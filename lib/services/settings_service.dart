import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:io' show File, Directory;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// خدمة إدارة إعدادات التطبيق
class SettingsService {
  static const String _keyLanguage = 'app_language';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyDefaultReportLanguage = 'default_report_language';
  static const String _keyShowWelcomeScreen = 'show_welcome_screen';
  static const String _keyAutoBackup = 'auto_backup';
  static const String _keyBackupInterval = 'backup_interval';
  static const String _keyOrganizationName = 'organization_name';
  static const String _keyOrganizationLogo = 'organization_logo';
  static const String _keyDataLocation = 'data_location';
  static const String _keyLastBackupTime = 'last_backup_time';
  static const String _keyBackupLocation = 'backup_location';
  static const String _keySharedSettingsUpdatedAt =
      'shared_settings_updated_at';
  static const String _keyCloudReconciliationComplete =
      'cloud_reconciliation_complete';

  static SharedPreferences? _prefs;

  /// تهيئة الخدمة
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// الحصول على SharedPreferences
  static Future<SharedPreferences> get prefs async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ==================== اللغة ====================

  /// الحصول على اللغة الافتراضية
  static Future<Locale> getDefaultLanguage() async {
    final p = await prefs;
    final langCode = p.getString(_keyLanguage) ?? 'ar';
    return Locale(langCode);
  }

  /// تعيين اللغة الافتراضية
  static Future<void> setDefaultLanguage(String languageCode) async {
    final p = await prefs;
    await p.setString(_keyLanguage, languageCode);
    _syncSharedSettings(p);
  }

  // ==================== المظهر ====================

  /// الحصول على وضع المظهر (فاتح/داكن/تلقائي)
  static Future<ThemeMode> getThemeMode() async {
    final p = await prefs;
    final mode = p.getString(_keyThemeMode) ?? 'light';
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  /// تعيين وضع المظهر
  static Future<void> setThemeMode(ThemeMode mode) async {
    final p = await prefs;
    String modeStr;
    switch (mode) {
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
      default:
        modeStr = 'light';
    }
    await p.setString(_keyThemeMode, modeStr);
    _syncSharedSettings(p);
  }

  // ==================== التقارير ====================

  /// الحصول على لغة التقارير الافتراضية
  static Future<String> getDefaultReportLanguage() async {
    final p = await prefs;
    return p.getString(_keyDefaultReportLanguage) ?? 'ar';
  }

  /// تعيين لغة التقارير الافتراضية
  static Future<void> setDefaultReportLanguage(String languageCode) async {
    final p = await prefs;
    await p.setString(_keyDefaultReportLanguage, languageCode);
    _syncSharedSettings(p);
  }

  // ==================== شاشة الترحيب ====================

  /// هل يتم إظهار شاشة الترحيب؟
  static Future<bool> getShowWelcomeScreen() async {
    final p = await prefs;
    return p.getBool(_keyShowWelcomeScreen) ?? true;
  }

  /// تعيين إظهار شاشة الترحيب
  static Future<void> setShowWelcomeScreen(bool show) async {
    final p = await prefs;
    await p.setBool(_keyShowWelcomeScreen, show);
    _syncSharedSettings(p);
  }

  // ==================== النسخ الاحتياطي ====================

  /// هل النسخ الاحتياطي التلقائي مفعل؟
  static Future<bool> getAutoBackup() async {
    final p = await prefs;
    return p.getBool(_keyAutoBackup) ?? false;
  }

  /// تعيين النسخ الاحتياطي التلقائي
  static Future<void> setAutoBackup(bool enabled) async {
    final p = await prefs;
    await p.setBool(_keyAutoBackup, enabled);
    _syncSharedSettings(p);
  }

  /// الحصول على فترة النسخ الاحتياطي (بالأيام)
  static Future<int> getBackupInterval() async {
    final p = await prefs;
    return p.getInt(_keyBackupInterval) ?? 7;
  }

  /// تعيين فترة النسخ الاحتياطي
  static Future<void> setBackupInterval(int days) async {
    final p = await prefs;
    await p.setInt(_keyBackupInterval, days);
    _syncSharedSettings(p);
  }

  /// الحصول على تاريخ آخر نسخة احتياطية
  static Future<DateTime?> getLastBackupTime() async {
    final p = await prefs;
    final timeStr = p.getString(_keyLastBackupTime);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  /// تعيين تاريخ آخر نسخة احتياطية
  static Future<void> setLastBackupTime(DateTime time) async {
    final p = await prefs;
    await p.setString(_keyLastBackupTime, time.toIso8601String());
  }

  // ==================== المنظمة ====================

  /// الحصول على اسم المنظمة
  static Future<String> getOrganizationName() async {
    final p = await prefs;
    return p.getString(_keyOrganizationName) ??
        'IHSAN İNSANİ YARDIMLAŞMA DERNEĞİ (جمعية إحسان للمساعدات الإنسانية)';
  }

  /// تعيين اسم المنظمة
  static Future<void> setOrganizationName(String name) async {
    final p = await prefs;
    await p.setString(_keyOrganizationName, name);
    _syncSharedSettings(p);
  }

  /// الحصول على مسار شعار المنظمة
  static Future<String?> getOrganizationLogo() async {
    final p = await prefs;
    return p.getString(_keyOrganizationLogo);
  }

  /// تعيين مسار شعار المنظمة
  static Future<void> setOrganizationLogo(String? path) async {
    final p = await prefs;
    if (path != null) {
      await p.setString(_keyOrganizationLogo, path);
    } else {
      await p.remove(_keyOrganizationLogo);
    }
  }

  // ==================== مسار البيانات ====================

  /// الحصول على مسار البيانات المخصص
  static Future<String?> getDataLocation() async {
    final p = await prefs;
    return p.getString(_keyDataLocation);
  }

  /// تعيين مسار البيانات المخصص
  static Future<void> setDataLocation(String? path) async {
    final p = await prefs;
    if (path != null) {
      await p.setString(_keyDataLocation, path);
    } else {
      await p.remove(_keyDataLocation);
    }
  }

  /// الحصول على مسار النسخ الاحتياطي المخصص
  static Future<String?> getBackupLocation() async {
    final p = await prefs;
    return p.getString(_keyBackupLocation);
  }

  /// تعيين مسار النسخ الاحتياطي المخصص
  static Future<void> setBackupLocation(String? path) async {
    final p = await prefs;
    if (path != null) {
      await p.setString(_keyBackupLocation, path);
    } else {
      await p.remove(_keyBackupLocation);
    }
  }

  /// الحصول على المسار الفعلي للبيانات (المستخدم حالياً)
  static Future<String> getEffectiveDataPath() async {
    final customPath = await getDataLocation();
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }
    // المسار الافتراضي
    if (kIsWeb) {
      return 'orphan_data'; // Just a prefix for web storage if used
    }
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'orphan_data');
  }

  // ==================== إعادة التعيين ====================

  /// إعادة تعيين جميع الإعدادات إلى القيم الافتراضية
  static Future<void> resetToDefaults() async {
    final p = await prefs;
    await p.remove(_keyLanguage);
    await p.remove(_keyThemeMode);
    await p.remove(_keyDefaultReportLanguage);
    await p.remove(_keyShowWelcomeScreen);
    await p.remove(_keyAutoBackup);
    await p.remove(_keyBackupInterval);
    await p.remove(_keyOrganizationName);
    await p.remove(_keyOrganizationLogo);
    await p.remove(_keyDataLocation);
    await p.remove(_keyLastBackupTime);
    await p.remove(_keyBackupLocation);
    _syncSharedSettings(p);
  }

  static void _syncSharedSettings(SharedPreferences preferences) {
    final updatedAt = DateTime.now().toUtc().toIso8601String();
    unawaited(() async {
      try {
        await preferences.setString(_keySharedSettingsUpdatedAt, updatedAt);
        await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('shared')
            .set(await getSharedSettingsForCloud());
      } catch (error, stackTrace) {
        debugPrint('Failed to sync shared settings to Firebase: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }());
  }

  static Future<Map<String, dynamic>> getSharedSettingsForCloud() async {
    final p = await prefs;
    return {
      'app_language': p.getString(_keyLanguage) ?? 'ar',
      'theme_mode': p.getString(_keyThemeMode) ?? 'light',
      'default_report_language': p.getString(_keyDefaultReportLanguage) ?? 'ar',
      'show_welcome_screen': p.getBool(_keyShowWelcomeScreen) ?? true,
      'auto_backup': p.getBool(_keyAutoBackup) ?? false,
      'backup_interval': p.getInt(_keyBackupInterval) ?? 7,
      'organization_name':
          p.getString(_keyOrganizationName) ??
          'IHSAN İNSANİ YARDIMLAŞMA DERNEĞİ (جمعية إحسان للمساعدات الإنسانية)',
      'updated_at':
          p.getString(_keySharedSettingsUpdatedAt) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toIso8601String(),
    };
  }

  static Future<void> applySharedSettingsFromCloud(
    Map<String, dynamic> values,
  ) async {
    final p = await prefs;
    final language = values['app_language'];
    if (language is String) await p.setString(_keyLanguage, language);
    final theme = values['theme_mode'];
    if (theme is String) await p.setString(_keyThemeMode, theme);
    final reportLanguage = values['default_report_language'];
    if (reportLanguage is String) {
      await p.setString(_keyDefaultReportLanguage, reportLanguage);
    }
    final showWelcome = values['show_welcome_screen'];
    if (showWelcome is bool) {
      await p.setBool(_keyShowWelcomeScreen, showWelcome);
    }
    final autoBackup = values['auto_backup'];
    if (autoBackup is bool) await p.setBool(_keyAutoBackup, autoBackup);
    final backupInterval = values['backup_interval'];
    if (backupInterval is int) {
      await p.setInt(_keyBackupInterval, backupInterval);
    }
    final organizationName = values['organization_name'];
    if (organizationName is String) {
      await p.setString(_keyOrganizationName, organizationName);
    }
    final updatedAt = values['updated_at'] ?? values['updatedAt'];
    if (updatedAt is Timestamp) {
      await p.setString(
        _keySharedSettingsUpdatedAt,
        updatedAt.toDate().toUtc().toIso8601String(),
      );
    } else if (updatedAt != null) {
      await p.setString(_keySharedSettingsUpdatedAt, updatedAt.toString());
    }
  }

  static Future<bool> hasCompletedCloudReconciliation() async {
    final p = await prefs;
    return p.getBool(_keyCloudReconciliationComplete) ?? false;
  }

  static Future<void> setCloudReconciliationComplete() async {
    final p = await prefs;
    await p.setBool(_keyCloudReconciliationComplete, true);
  }

  /// نقل البيانات من المسار الحالي إلى مسار جديد
  static Future<void> moveDataTo(String targetPath) async {
    if (kIsWeb) return; // Not supported on web browser
    final currentPath = await getEffectiveDataPath();
    final sourceDir = Directory(currentPath);
    final targetDir = Directory(targetPath);

    if (currentPath == targetPath) return; // نفس المسار

    if (!await sourceDir.exists()) {
      return; // لا توجد بيانات لنقلها
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    await _copyDirectory(sourceDir, targetDir);
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    if (kIsWeb) return;
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        var newDirectory = Directory(
          p.join(destination.absolute.path, p.basename(entity.path)),
        );
        await newDirectory.create();
        await _copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }
}
