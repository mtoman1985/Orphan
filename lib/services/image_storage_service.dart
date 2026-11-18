import 'package:flutter/foundation.dart';
import 'github_storage_service.dart';

/// خدمة تخزين الصور - واجهة موحدة
/// يمكن التبديل بين Firebase Storage و GitHub Storage بسهولة
class ImageStorageService {
  // استخدام GitHub Storage كافتراضي
  static final StorageProvider _provider = StorageProvider.github;

  /// رفع صورة يتيم
  static Future<String?> uploadOrphanImage({
    required Uint8List imageBytes,
    required String orphanId,
  }) async {
    switch (_provider) {
      case StorageProvider.github:
        final fileName = GitHubStorageService.generateFileName(
          prefix: 'orphan_$orphanId',
          extension: 'jpg',
        );
        return await GitHubStorageService.uploadImage(
          bytes: imageBytes,
          fileName: fileName,
          folder: 'orphans',
        );

      case StorageProvider.firebase:
        // TODO: تنفيذ Firebase Storage إذا احتجته مستقبلاً
        throw UnimplementedError('Firebase Storage not implemented');
    }
  }

  /// رفع صورة كفيل
  static Future<String?> uploadSponsorImage({
    required Uint8List imageBytes,
    required String sponsorId,
  }) async {
    switch (_provider) {
      case StorageProvider.github:
        final fileName = GitHubStorageService.generateFileName(
          prefix: 'sponsor_$sponsorId',
          extension: 'jpg',
        );
        return await GitHubStorageService.uploadImage(
          bytes: imageBytes,
          fileName: fileName,
          folder: 'sponsors',
        );

      case StorageProvider.firebase:
        throw UnimplementedError('Firebase Storage not implemented');
    }
  }

  /// رفع صورة عامة
  static Future<String?> uploadGeneralImage({
    required Uint8List imageBytes,
    required String category,
    String? customFileName,
  }) async {
    switch (_provider) {
      case StorageProvider.github:
        final fileName =
            customFileName ??
            GitHubStorageService.generateFileName(
              prefix: category,
              extension: 'jpg',
            );
        return await GitHubStorageService.uploadImage(
          bytes: imageBytes,
          fileName: fileName,
          folder: category,
        );

      case StorageProvider.firebase:
        throw UnimplementedError('Firebase Storage not implemented');
    }
  }

  /// تحميل صورة
  static Future<Uint8List?> downloadImage(String imageUrl) async {
    switch (_provider) {
      case StorageProvider.github:
        return await GitHubStorageService.downloadImage(imageUrl);

      case StorageProvider.firebase:
        throw UnimplementedError('Firebase Storage not implemented');
    }
  }

  /// حذف صورة
  static Future<bool> deleteImage(String imageUrl) async {
    switch (_provider) {
      case StorageProvider.github:
        final filePath = GitHubStorageService.extractPathFromUrl(imageUrl);
        if (filePath == null) {
          debugPrint('ImageStorage: فشل استخراج المسار من الرابط');
          return false;
        }
        return await GitHubStorageService.deleteImage(filePath);

      case StorageProvider.firebase:
        throw UnimplementedError('Firebase Storage not implemented');
    }
  }

  /// الحصول على مزود التخزين الحالي
  static StorageProvider get currentProvider => _provider;
}

/// أنواع مزودي التخزين
enum StorageProvider { github, firebase }
