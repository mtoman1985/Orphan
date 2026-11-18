import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path/path.dart' as p;
import 'settings_service.dart';

/// GitHub Storage Service
/// بديل مجاني لـ Firebase Storage - يستخدم GitHub Repository لتخزين الصور
class GitHubStorageService {
  // TODO: استبدل هذه القيم بمعلوماتك من GitHub
  static const String _owner =
      'mtoman1985atef-sketch'; // اسم المستخدم في GitHub
  static const String _repo = 'orphan-images'; // اسم الـ repository
  static final bool _writesEnabled = false;
  static const String _branch = 'main'; // اسم الفرع

  static Map<String, String> getHeaders() {
    return {'Accept': 'application/vnd.github.v3+json'};
  }

  // Base URL للـ GitHub API
  static const String _apiBaseUrl = 'https://api.github.com';
  static const String _rawBaseUrl = 'https://raw.githubusercontent.com';

  /// رفع صورة إلى GitHub Repository
  ///
  /// [bytes] - بيانات الصورة
  /// [fileName] - اسم الملف المراد حفظه
  /// [folder] - المجلد (اختياري)
  ///
  /// يرجع: رابط الصورة المباشر أو null في حالة الفشل
  static Future<String?> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String folder = 'images',
  }) async {
    if (!_writesEnabled) {
      debugPrint(
        'GitHub image uploads are disabled until a server-side proxy is configured.',
      );
      return null;
    }

    try {
      // إنشاء المسار الكامل
      final String filePath = '$folder/$fileName';

      // تحويل البيانات إلى Base64
      final String base64Content = base64.encode(bytes);

      // بناء الـ API URL
      final String apiUrl =
          '$_apiBaseUrl/repos/$_owner/$_repo/contents/$filePath';

      // التحقق من وجود الملف (للحصول على SHA في حالة التحديث)
      String? existingSha;
      try {
        final checkResponse = await http.get(
          Uri.parse(apiUrl),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        );

        if (checkResponse.statusCode == 200) {
          final data = json.decode(checkResponse.body);
          existingSha = data['sha'];
          debugPrint('GitHub Storage: الملف موجود مسبقاً، سيتم التحديث');
        }
      } catch (e) {
        // الملف غير موجود، سنقوم بإنشائه
        debugPrint('GitHub Storage: ملف جديد');
      }

      // بناء جسم الطلب
      final Map<String, dynamic> requestBody = {
        'message': 'Upload image: $fileName',
        'content': base64Content,
        'branch': _branch,
      };

      // إضافة SHA في حالة التحديث
      if (existingSha != null) {
        requestBody['sha'] = existingSha;
      }

      // إرسال الطلب
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // نجح الرفع - بناء رابط الصورة المباشر
        final String imageUrl =
            '$_rawBaseUrl/$_owner/$_repo/$_branch/$filePath';
        debugPrint('GitHub Storage: تم رفع الصورة بنجاح - $imageUrl');
        return imageUrl;
      } else {
        debugPrint('GitHub Storage: فشل رفع الصورة - ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('GitHub Storage Error: $e');
      return null;
    }
  }

  /// تحميل صورة من GitHub
  ///
  /// [imageUrl] - رابط الصورة المباشر
  ///
  /// يرجع: بيانات الصورة أو null في حالة الفشل
  static Future<Uint8List?> downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        debugPrint('GitHub Storage: تم تحميل الصورة بنجاح');
        return response.bodyBytes;
      } else if (response.statusCode != 404) {
        debugPrint('GitHub Storage: فشل تحميل الصورة - ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('GitHub Storage Error: $e');
      return null;
    }
  }

  /// حذف صورة من GitHub
  ///
  /// [filePath] - المسار الكامل للملف (مثل: images/orphan_123.jpg)
  static Future<bool> deleteImage(String filePath) async {
    if (!_writesEnabled) {
      debugPrint(
        'GitHub image deletion is disabled until a server-side proxy is configured.',
      );
      return false;
    }

    try {
      final String apiUrl =
          '$_apiBaseUrl/repos/$_owner/$_repo/contents/$filePath';

      // الحصول على SHA للملف
      final checkResponse = await http.get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (checkResponse.statusCode != 200) {
        debugPrint('GitHub Storage: الملف غير موجود');
        return false;
      }

      final data = json.decode(checkResponse.body);
      final String sha = data['sha'];

      // حذف الملف
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': 'Delete image: $filePath',
          'sha': sha,
          'branch': _branch,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('GitHub Storage: تم حذف الصورة بنجاح');
        return true;
      } else {
        debugPrint('GitHub Storage: فشل حذف الصورة - ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('GitHub Storage Error: $e');
      return false;
    }
  }

  /// بناء رابط الصورة المباشر من المسار
  static String getImageUrl(String filePath) {
    final encodedPath = filePath.split('/').map(Uri.encodeComponent).join('/');
    return '$_rawBaseUrl/$_owner/$_repo/$_branch/$encodedPath';
  }

  /// استخراج المسار من رابط الصورة
  static String? extractPathFromUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // التخطي: owner/repo/branch
      if (pathSegments.length > 3) {
        return pathSegments.sublist(3).join('/');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// توليد اسم ملف فريد
  static String generateFileName({
    required String prefix,
    String extension = 'jpg',
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.$extension';
  }

  /// Fix image URLs for Web display (GitHub Links)
  static String _cachedDataPath = '';

  static Future<void> fixChildPaths(dynamic child) async {
    // On web, we don't need to check file existence, just build URLs
    if (kIsWeb) {
      _fixChildPathsWeb(child);
      return;
    }

    // Desktop: Check file existence
    if (_cachedDataPath.isEmpty) {
      _cachedDataPath = await SettingsService.getEffectiveDataPath();
    }

    String? fix(String? fileName, String? currentPath) {
      if (fileName == null || fileName.isEmpty) {
        // Try to get filename from currentPath if needed
        if (currentPath != null && currentPath.isNotEmpty) {
          fileName = p.basename(currentPath);
        } else {
          return null;
        }
      }

      // Extract filename from path (handling both Windows and Unix separators)
      String cleanName = p.basename(fileName);

      // Windows: If path is already absolute, leave it. If not, prefix it.
      if (currentPath != null &&
          currentPath.isNotEmpty &&
          p.isAbsolute(currentPath)) {
        return currentPath;
      }
      // Check if it exists in 'files' or 'children/ID/'
      // The convention seems to be children/ID/name in StorageService
      // and 'files' in some export logic.
      final pathInChildDir = p.join(
        _cachedDataPath,
        'children',
        child.childIdNumber,
        cleanName,
      );
      if (File(pathInChildDir).existsSync()) return pathInChildDir;

      final pathInFiles = p.join(_cachedDataPath, 'files', cleanName);
      return pathInFiles; // Fallback
    }

    if (child.childPhotoFileName != null || child.childPhotoPath != null) {
      child.childPhotoPath = fix(
        child.childPhotoFileName,
        child.childPhotoPath,
      );
    }
    if (child.motherIdPhotoFileName != null ||
        child.motherIdPhotoPath != null) {
      child.motherIdPhotoPath = fix(
        child.motherIdPhotoFileName,
        child.motherIdPhotoPath,
      );
    }
    if (child.guardianIdPhotoFileName != null ||
        child.guardianIdPhotoPath != null) {
      child.guardianIdPhotoPath = fix(
        child.guardianIdPhotoFileName,
        child.guardianIdPhotoPath,
      );
    }
    if (child.fatherDeathCertificateFileName != null ||
        child.fatherDeathCertificatePath != null) {
      child.fatherDeathCertificatePath = fix(
        child.fatherDeathCertificateFileName,
        child.fatherDeathCertificatePath,
      );
    }
    if (child.motherDeathCertificateFileName != null ||
        child.motherDeathCertificatePath != null) {
      child.motherDeathCertificatePath = fix(
        child.motherDeathCertificateFileName,
        child.motherDeathCertificatePath,
      );
    }

    // Update documents
    for (var doc in child.documents) {
      doc.filePath = fix(doc.fileName, doc.filePath) ?? '';
    }
  }

  /// Fast synchronous path fixing for web
  static void _fixChildPathsWeb(dynamic child) {
    bool isRemoteUrl(String? value) {
      final uri = Uri.tryParse(value ?? '');
      return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    }

    String? buildWebUrl(String? fileName, String? currentPath) {
      if (isRemoteUrl(currentPath)) return currentPath;
      if (fileName == null || fileName.isEmpty) {
        if (currentPath != null && currentPath.isNotEmpty) {
          fileName = p.basename(currentPath);
        } else {
          return null;
        }
      }

      String cleanName = p.basename(fileName);
      return getImageUrl('children/${child.childIdNumber}/$cleanName');
    }

    if (child.childPhotoFileName != null || child.childPhotoPath != null) {
      child.childPhotoPath = buildWebUrl(
        child.childPhotoFileName,
        child.childPhotoPath,
      );
    }
    if (child.motherIdPhotoFileName != null ||
        child.motherIdPhotoPath != null) {
      child.motherIdPhotoPath = buildWebUrl(
        child.motherIdPhotoFileName,
        child.motherIdPhotoPath,
      );
    }
    if (child.guardianIdPhotoFileName != null ||
        child.guardianIdPhotoPath != null) {
      child.guardianIdPhotoPath = buildWebUrl(
        child.guardianIdPhotoFileName,
        child.guardianIdPhotoPath,
      );
    }
    if (child.fatherDeathCertificateFileName != null ||
        child.fatherDeathCertificatePath != null) {
      child.fatherDeathCertificatePath = buildWebUrl(
        child.fatherDeathCertificateFileName,
        child.fatherDeathCertificatePath,
      );
    }
    if (child.motherDeathCertificateFileName != null ||
        child.motherDeathCertificatePath != null) {
      child.motherDeathCertificatePath = buildWebUrl(
        child.motherDeathCertificateFileName,
        child.motherDeathCertificatePath,
      );
    }

    // Update documents
    for (var doc in child.documents) {
      doc.filePath = buildWebUrl(doc.fileName, doc.filePath) ?? '';
    }
  }

  static void fixChildImageUrls(dynamic child) {
    // Legacy support: call the new async version in fire-and-forget or just handle web
    if (kIsWeb) {
      _fixChildPathsWeb(child);
    }
  }
}
