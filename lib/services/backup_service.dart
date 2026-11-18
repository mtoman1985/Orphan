import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
// تم حذف دعم Firebase
import 'settings_service.dart';

class BackupService {
  /// Create a compressed backup of the data directory
  static Future<File> createBackup() async {
    if (kIsWeb) {
      throw UnimplementedError('Backup to local file is not supported on web');
    }
    final dataPath = await SettingsService.getEffectiveDataPath();
    final sourceDir = Directory(dataPath);

    if (!await sourceDir.exists()) {
      throw Exception('Data directory not found');
    }

    // Create backups directory
    final customBackupPath = await SettingsService.getBackupLocation();
    Directory backupsDir;

    if (customBackupPath != null && customBackupPath.isNotEmpty) {
      backupsDir = Directory(customBackupPath);
    } else {
      // Default: parent of data directory
      final parentDir = sourceDir.parent;
      backupsDir = Directory(p.join(parentDir.path, 'orphans_backups'));
    }

    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }

    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final zipPath = p.join(backupsDir.path, 'backup_$timestamp.zip');

    var encoder = ZipFileEncoder();
    try {
      encoder.create(zipPath);
      // Add the directory contents
      encoder.addDirectory(sourceDir);
    } catch (e) {
      throw Exception('Failed to zip data: $e');
    } finally {
      encoder.close();
    }

    return File(zipPath);
  }

  // تم حذف دالة رفع النسخة الاحتياطية إلى Firebase
}
