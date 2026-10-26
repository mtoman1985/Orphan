import 'package:flutter/foundation.dart';
import 'dart:io' show File, Directory;
import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/child.dart';
import '../models/document.dart';

import 'settings_service.dart';
import 'sqlite_service.dart';
import 'web_cache_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<Directory> getBaseDir() async {
    if (kIsWeb)
      throw UnsupportedError('Local directory access is not supported on web');
    final path = await SettingsService.getEffectiveDataPath();
    final appDir = Directory(path);
    if (!await appDir.exists()) await appDir.create(recursive: true);
    return appDir;
  }

  Future<File> _childFile(String id) async {
    if (kIsWeb)
      throw UnsupportedError('Local file access is not supported on web');
    final base = await getBaseDir();
    final file = File('${base.path}/children/$id.json');
    final parent = file.parent;
    if (!await parent.exists()) await parent.create(recursive: true);
    return file;
  }

  /// Unified method to list children from the appropriate source
  Future<List<Child>> listChildren() async {
    if (kIsWeb) {
      // Use cache service on web for better performance
      return await WebCacheService().getChildren();
    } else {
      // Use SQLite for desktop as it is the primary local storage now
      return await SqliteService().listChildren();
    }
  }

  // Legacy local file save (might act as backup or be unused if SQLite is primary)
  Future<void> saveChild(Child child) async {
    if (kIsWeb) return; // Cannot save locally on web
    try {
      final f = await _childFile(child.id);
      await f.writeAsString(child.toRawJson());
    } catch (e) {
      debugPrint('Error saving child to simplified JSON: $e');
    }
  }

  Future<Document> saveFile(
    File src, {
    required String type,
    String? customFileName,
  }) async {
    if (kIsWeb) throw UnsupportedError('File saving is not supported on web');
    final base = await getBaseDir();
    final filesDir = Directory('${base.path}/files');
    if (!await filesDir.exists()) await filesDir.create(recursive: true);
    final id = Uuid().v4();

    // Use custom file name if provided, otherwise generate from source file
    final fileName = customFileName ?? '${id}_${src.uri.pathSegments.last}';
    final dest = File('${filesDir.path}/$fileName');
    await src.copy(dest.path);

    final doc = Document(
      id: id,
      fileName: customFileName ?? src.uri.pathSegments.last,
      filePath: dest.path,
      type: type,
    );
    return doc;
  }

  Future<File> generateMonthlyReportPdf(
    String childId,
    String sponsorName,
    DateTime month,
    Map<String, dynamic> data,
  ) async {
    if (kIsWeb)
      throw UnsupportedError('Local PDF generation is not supported on web');
    // Minimal stub that writes a JSON summary as .pdf placeholder.
    // A real implementation would use the `pdf` package to create a proper PDF.
    final base = await getBaseDir();
    final reportsDir = Directory('${base.path}/reports');
    if (!await reportsDir.exists()) await reportsDir.create(recursive: true);
    final file = File(
      '${reportsDir.path}/report_${childId}_${month.year}_${month.month}.pdf',
    );
    final content =
        'Monthly report for $sponsorName\nChild: $childId\nMonth: ${month.year}-${month.month}\n\nData:\n${json.encode(data)}';
    await file.writeAsBytes(content.codeUnits);
    return file;
  }
}
