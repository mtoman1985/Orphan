import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child.dart';
import '../config/cloud_config.dart';
import 'storage_service.dart';
import 'image_storage_service.dart';

class CloudSyncService {
  final String baseUrl;
  final StorageService _storage = StorageService();

  CloudSyncService({String? baseUrl})
    : baseUrl = baseUrl ?? CloudConfig.baseUrl;

  /// تحميل بيانات اليتيم إلى Firebase
  Future<void> uploadChild(Child child) async {
    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(child.id)
          .set(child.toJson());
    } catch (e) {
      throw Exception('Error uploading child to Firebase: $e');
    }
  }

  /// تحميل صورة إلى السحابة (GitHub)
  Future<String> uploadImage(
    File imageFile,
    String childId,
    String imageType,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final originalFileName = path.basename(imageFile.path);

      final imageUrl = await ImageStorageService.uploadGeneralImage(
        imageBytes: bytes,
        category: 'orphans',
        customFileName: originalFileName,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image to GitHub Storage');
      }

      return imageUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// تحميل عدة صور دفعة واحدة
  Future<Map<String, String>> uploadMultipleImages(
    Map<String, File> images,
    String childId,
  ) async {
    final results = <String, String>{};

    for (final entry in images.entries) {
      try {
        final url = await uploadImage(entry.value, childId, entry.key);
        results[entry.key] = url;
      } catch (e) {
        results[entry.key] = 'error: $e';
      }
    }

    return results;
  }

  /// تنزيل صورة من السحابة
  Future<File> downloadImage(String childId, String imageType) async {
    if (kIsWeb) {
      throw UnimplementedError(
        'File-based image download is not supported on web',
      );
    }
    try {
      final url = Uri.parse('$baseUrl/children/$childId/images/$imageType');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      final baseDir = await _storage.getBaseDir();
      final imageDir = Directory('${baseDir.path}/cloud_images');

      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final fileName =
          '${childId}_${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${imageDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      throw Exception('Error downloading image: $e');
    }
  }

  /// تنزيل بيانات اليتيم من Firebase
  Future<Child> downloadChild(String childId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('children')
              .doc(childId)
              .get();
      if (!doc.exists) {
        throw Exception('Child not found in Firebase');
      }
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] = doc.id;
      return Child.fromJson(data);
    } catch (e) {
      throw Exception('Error downloading child data from Firebase: $e');
    }
  }

  /// تنزيل قائمة جميع الأطفال من Firebase
  Future<List<Child>> downloadAllChildren() async {
    try {
      final query =
          await FirebaseFirestore.instance.collection('children').get();
      return query.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Child.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error downloading children list from Firebase: $e');
    }
  }

  /// مزامنة اليتيم كاملاً مع الصور
  Future<void> syncChild(Child child, Map<String, File> images) async {
    try {
      await uploadChild(child);
      if (images.isNotEmpty) {
        await uploadMultipleImages(images, child.id);
      }
    } catch (e) {
      throw Exception('Error syncing child: $e');
    }
  }

  /// التحقق من توفر الاتصال بالإنترنت والوصول لـ GitHub
  Future<bool> checkConnection() async {
    if (kIsWeb) {
      // On Web, we can't use InternetAddress. Just check if we can reach a public URL
      try {
        final response = await http
            .get(Uri.parse('https://api.github.com'))
            .timeout(const Duration(seconds: 5));
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
    try {
      final result = await InternetAddress.lookup(
        'api.github.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على حالة المزامنة
  Future<Map<String, dynamic>> getSyncStatus(String childId) async {
    try {
      final url = Uri.parse('$baseUrl/children/$childId/sync-status');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to get sync status: ${response.statusCode}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Error getting sync status: $e');
    }
  }

  /// حذف بيانات من Firebase
  Future<void> deleteChildFromCloud(String childId) async {
    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting child from Firebase: $e');
    }
  }

  /// تحميل نسخة احتياطية كاملة
  Future<File> downloadBackup() async {
    try {
      final url = Uri.parse('$baseUrl/backup/download');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to download backup: ${response.statusCode}');
      }

      final baseDir = await _storage.getBaseDir();
      final backupFile = File(
        '${baseDir.path}/backups/backup_${DateTime.now().toIso8601String()}.zip',
      );

      await backupFile.parent.create(recursive: true);
      await backupFile.writeAsBytes(response.bodyBytes);

      return backupFile;
    } catch (e) {
      throw Exception('Error downloading backup: $e');
    }
  }

  /// تحميل نسخة احتياطية كاملة إلى السحابة
  Future<void> uploadBackup(File backupFile) async {
    try {
      final url = Uri.parse('$baseUrl/backup/upload');

      var request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath(
          'backup',
          backupFile.path,
          filename: path.basename(backupFile.path),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload backup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading backup: $e');
    }
  }
}
