/// Configuration file for Cloud Sync Service
/// ملف التكوين لخدمة المزامنة السحابية
library;

class CloudConfig {
  /// Server base URL
  /// عنوان الخادم الأساسي
  static const String baseUrl = 'http://localhost:3000/api';

  /// Enable debug logging
  /// تفعيل تسجيل الأخطاء
  static const bool debugMode = true;

  /// Request timeout in seconds
  /// مهلة انتظار الطلب بالثواني
  static const int requestTimeout = 30;

  /// Maximum image size in MB
  /// الحد الأقصى لحجم الصور بالميجابايت
  static const double maxImageSizeMB = 10.0;

  /// Image quality (0-100)
  /// جودة الصورة (0-100)
  static const int imageQuality = 85;

  /// Auto sync interval in minutes
  /// فترة المزامنة التلقائية بالدقائق
  static const int autoSyncIntervalMinutes = 5;

  /// Enable auto sync
  /// تفعيل المزامنة التلقائية
  static const bool enableAutoSync = false;

  /// Enable offline queue
  /// تفعيل قائمة الانتظار للوضع غير المتصل
  static const bool enableOfflineQueue = false;

  /// Enable image compression
  /// تفعيل ضغط الصور
  static const bool enableImageCompression = false;

  /// Backup retention days
  /// عدد أيام الاحتفاظ بالنسخ الاحتياطية
  static const int backupRetentionDays = 30;

  /// Cloud storage provider
  /// مزود خدمة التخزين السحابي
  static const String cloudProvider = 'local'; // 'local', 'aws-s3', 'dropbox'

  /// Change server URL
  /// تغيير عنوان الخادم
  static String getServerUrl({String? customUrl}) {
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }
    return baseUrl;
  }

  /// Get full endpoint URL
  /// الحصول على عنوان النقطة الكاملة
  static String getEndpoint(String path) {
    return '${baseUrl.replaceAll(RegExp(r'/$'), '')}/$path'.replaceAll(
      RegExp(r'/+'),
      '/',
    );
  }

  /// Log debug message
  /// تسجيل رسالة تصحيح
  static void log(String message) {
    if (debugMode) {
      print('[CloudSync] $message');
    }
  }

  /// Get image constraints
  /// الحصول على قيود الصور
  static Map<String, dynamic> getImageConstraints() {
    return {
      'maxSize': maxImageSizeMB * 1024 * 1024, // Convert to bytes
      'quality': imageQuality,
      'compression': enableImageCompression,
    };
  }
}
