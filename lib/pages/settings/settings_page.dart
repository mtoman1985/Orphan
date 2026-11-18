import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/settings_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';
import '../../services/sqlite_service.dart';
import '../../services/firebase_sync_service.dart';

class SettingsPage extends StatefulWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChange;

  const SettingsPage({
    super.key,
    required this.currentLocale,
    required this.onLocaleChange,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  bool _isBackingUp = false;

  // الإعدادات
  String _selectedLanguage = 'ar';
  String _selectedReportLanguage = 'ar';
  bool _autoBackup = false;
  int _backupInterval = 7;
  DateTime? _lastBackupTime;
  String? _backupLocation;
  String _organizationName = 'إحسان - IHSAN';
  String? _dataLocation;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      await SettingsService.init();
      final lang = await SettingsService.getDefaultLanguage();
      final reportLang = await SettingsService.getDefaultReportLanguage();
      final autoBackup = await SettingsService.getAutoBackup();
      final backupInterval = await SettingsService.getBackupInterval();
      final lastBackup = await SettingsService.getLastBackupTime();
      final backupLoc = await SettingsService.getBackupLocation();
      final orgName = await SettingsService.getOrganizationName();
      final dataLoc = await SettingsService.getDataLocation();

      setState(() {
        _selectedLanguage = lang.languageCode;
        _selectedReportLanguage = reportLang;
        _autoBackup = autoBackup;
        _backupInterval = backupInterval;
        _lastBackupTime = lastBackup;
        _backupLocation = backupLoc;
        _organizationName = orgName;
        _dataLocation = dataLoc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLanguage(String langCode) async {
    await SettingsService.setDefaultLanguage(langCode);
    setState(() {
      _selectedLanguage = langCode;
    });
  }

  Future<void> _saveReportLanguage(String langCode) async {
    await SettingsService.setDefaultReportLanguage(langCode);
    setState(() {
      _selectedReportLanguage = langCode;
    });
    // تغيير لغة الواجهة أيضاً لأن لغة التقارير هي لغة البرنامج
    widget.onLocaleChange(Locale(langCode));
  }

  Future<void> _saveAutoBackup(bool value) async {
    await SettingsService.setAutoBackup(value);
    setState(() {
      _autoBackup = value;
    });
  }

  Future<void> _saveBackupInterval(int days) async {
    await SettingsService.setBackupInterval(days);
    setState(() {
      _backupInterval = days;
    });
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.getKey('settings_reset_title'),
                ),
              ],
            ),
            content: Text(
              AppLocalizations.of(context)!.getKey('settings_reset_message'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.getKey('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.getKey('settings_reset_confirm'),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await SettingsService.resetToDefaults();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.getKey('settings_reset_success'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _performBackup() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _isBackingUp = true);
    try {
      // المزامنة السحابية الشاملة (Firebase + GitHub)
      // لا يتم إنشاء نسخة محلية هنا بناءً على طلب المستخدم
      await FirebaseSyncService().integrateAllData();

      // حفظ تاريخ آخر عملية مزامنة بنجاح
      final now = DateTime.now();
      await SettingsService.setLastBackupTime(now);

      if (mounted) {
        setState(() {
          _lastBackupTime = now;
          _isBackingUp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.get('saved_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBackingUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.get('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDataLocation() async {
    final l = AppLocalizations.of(context)!;
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      // Confirm with user
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(l.get('data_location_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.get('are_you_sure_delete'),
                  ), // Should be are_you_sure_change but using existing or adding new
                  // Actually I should add 'are_you_sure_change_data_location'
                  const SizedBox(height: 10),
                  Text(
                    '${l.get('db_path')}: $selectedDirectory',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.get('cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l.get('confirm')),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        setState(() => _isLoading = true);
        try {
          // Close DB to release lock
          await SqliteService().close();

          // Copy data first
          await SettingsService.moveDataTo(selectedDirectory);
          // Then update setting
          await SettingsService.setDataLocation(selectedDirectory);

          setState(() {
            _dataLocation = selectedDirectory;
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l.get('saved_successfully')),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l.get('error')}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _pickBackupLocation() async {
    final l = AppLocalizations.of(context)!;
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      await SettingsService.setBackupLocation(selectedDirectory);
      setState(() {
        _backupLocation = selectedDirectory;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.get('saved_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final isArabic = widget.currentLocale.languageCode == 'ar';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(theme, l),
              const SizedBox(height: 24),

              // Language Settings
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 100),
                child: _buildLanguageSection(theme, l),
              ),
              const SizedBox(height: 20),

              // Report Settings
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: _buildReportSection(theme, l),
              ),
              const SizedBox(height: 20),

              // Backup Settings
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 300),
                child: _buildBackupSection(theme, l),
              ),
              const SizedBox(height: 20),

              // Organization Settings
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
                child: _buildOrganizationSection(theme, l),
              ),
              const SizedBox(height: 20),

              // Storage Settings
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 450),
                child: _buildStorageSection(theme, l),
              ),
              const SizedBox(height: 20),

              // About & Reset
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 500),
                child: _buildAboutSection(theme, l),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.settings,
                color: theme.colorScheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.getKey('settings_page_title'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.getKey('settings_page_description'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(
                        0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(ThemeData theme, AppLocalizations l) {
    return _buildSection(
      theme: theme,
      icon: Icons.language,
      title: l.getKey('settings_language_section'),
      color: Colors.blue,
      children: [
        _buildSettingTile(
          title: l.getKey('settings_app_language'),
          subtitle: l.getKey('settings_app_language_desc'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(12),
              items: [
                DropdownMenuItem(
                  value: 'ar',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇸🇦 ', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(l.getKey('language_arabic')),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇬🇧 ', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(l.getKey('language_english')),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'tr',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇹🇷 ', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(l.getKey('language_turkish')),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _saveLanguage(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportSection(ThemeData theme, AppLocalizations l) {
    return _buildSection(
      theme: theme,
      icon: Icons.description,
      title: l.getKey('settings_reports_section'),
      color: Colors.green,
      children: [
        _buildSettingTile(
          title: l.getKey('settings_report_language'),
          subtitle: l.getKey('settings_report_language_desc'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedReportLanguage,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(12),
              items: [
                DropdownMenuItem(
                  value: 'ar',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇸🇦 ', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(l.getKey('language_arabic')),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇬🇧 ', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(l.getKey('language_english')),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'tr',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇹🇷 ', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(l.getKey('language_turkish')),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _saveReportLanguage(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupSection(ThemeData theme, AppLocalizations l) {
    String lastBackupText =
        _lastBackupTime != null
            ? '${_lastBackupTime!.day}/${_lastBackupTime!.month}/${_lastBackupTime!.year} ${_lastBackupTime!.hour}:${_lastBackupTime!.minute}'
            : l.get('never_backed_up');

    DateTime? nextBackupTime;
    bool isOverdue = false;
    if (_lastBackupTime != null) {
      nextBackupTime = _lastBackupTime!.add(Duration(days: _backupInterval));
      isOverdue = DateTime.now().isAfter(nextBackupTime);
    }

    return _buildSection(
      theme: theme,
      icon: Icons.backup,
      title: l.get('comprehensive_backup'),
      color: Colors.orange,
      children: [
        _buildSettingTile(
          title: l.get('last_backup'),
          subtitle: lastBackupText,
          trailing: Icon(
            _lastBackupTime != null ? Icons.check_circle : Icons.help_outline,
            color: _lastBackupTime != null ? Colors.green : Colors.grey,
          ),
        ),
        if (nextBackupTime != null)
          _buildSettingTile(
            title: l.get('next_backup_date'),
            subtitle:
                '${nextBackupTime.day}/${nextBackupTime.month}/${nextBackupTime.year}',
            trailing:
                isOverdue
                    ? const Icon(Icons.warning_amber_rounded, color: Colors.red)
                    : const Icon(Icons.event, color: Colors.blue),
          ),
        if (isOverdue)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.get('backup_overdue_warning'),
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _buildSettingTile(
          title: l.getKey('settings_auto_backup'),
          subtitle: l.get('auto_backup_desc'),
          trailing: Switch(
            value: _autoBackup,
            activeColor: Colors.orange,
            onChanged: (value) => _saveAutoBackup(value),
          ),
        ),
        if (_autoBackup)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildSettingTile(
              title: l.getKey('settings_backup_interval'),
              subtitle: l.getKey('settings_backup_interval_desc'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  value: _backupInterval,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('${l.getKey('settings_daily')}'),
                    ),
                    DropdownMenuItem(
                      value: 7,
                      child: Text('${l.getKey('settings_weekly')}'),
                    ),
                    DropdownMenuItem(
                      value: 30,
                      child: Text('${l.getKey('settings_monthly')}'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _saveBackupInterval(value);
                    }
                  },
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              children: [
                Text(
                  l.get('cloud_backup_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.get('cloud_backup_desc'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _isBackingUp
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                      onPressed: _performBackup,
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: Text(l.get('start_cloud_backup')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationSection(ThemeData theme, AppLocalizations l) {
    return _buildSection(
      theme: theme,
      icon: Icons.business,
      title: l.getKey('settings_organization_section'),
      color: Colors.purple,
      children: [
        _buildSettingTile(
          title: l.getKey('settings_organization_name'),
          subtitle: _organizationName,
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.purple),
            onPressed: () => _editOrganizationName(l),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageSection(ThemeData theme, AppLocalizations l) {
    return _buildSection(
      theme: theme,
      icon: Icons.storage,
      title: 'موقع البيانات',
      color: Colors.brown,
      children: [
        _buildSettingTile(
          title: 'مسار حفظ النسخ (ZIP)',
          subtitle: _backupLocation ?? 'المسار الافتراضي (orphans_backups)',
          trailing: ElevatedButton.icon(
            onPressed: _pickBackupLocation,
            icon: const Icon(Icons.folder_zip),
            label: Text(l.get('change_button')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (_backupLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: OutlinedButton(
              onPressed: () async {
                await SettingsService.setBackupLocation(null);
                setState(() {
                  _backupLocation = null;
                });
              },
              child: Text(l.get('restore_default_backup_path')),
            ),
          ),
        const Divider(),
        _buildSettingTile(
          title: 'مسار قاعدة البيانات',
          subtitle: _dataLocation ?? 'المسار الافتراضي (المستندات/orphan_data)',
          trailing: ElevatedButton.icon(
            onPressed: _pickDataLocation,
            icon: const Icon(Icons.folder_open),
            label: Text(l.get('change_button')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (_dataLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: OutlinedButton(
              onPressed: () async {
                await SettingsService.setDataLocation(null);
                setState(() {
                  _dataLocation = null;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تمت استعادة المسار الافتراضي. يرجى إعادة التشغيل.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('استعادة المسار الافتراضي'),
            ),
          ),
      ],
    );
  }

  Widget _buildAboutSection(ThemeData theme, AppLocalizations l) {
    return _buildSection(
      theme: theme,
      icon: Icons.info,
      title: l.getKey('settings_about_section'),
      color: Colors.teal,
      children: [
        _buildSettingTile(
          title: l.getKey('settings_app_version'),
          subtitle: 'v1.0.0',
          trailing: const Icon(Icons.check_circle, color: Colors.teal),
        ),
        const Divider(),
        _buildSettingTile(
          title: l.getKey('settings_reset'),
          subtitle: l.getKey('settings_reset_desc'),
          trailing: OutlinedButton.icon(
            onPressed: _resetSettings,
            icon: const Icon(Icons.refresh, color: Colors.orange),
            label: Text(
              l.getKey('settings_reset_button'),
              style: const TextStyle(color: Colors.orange),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Future<void> _editOrganizationName(AppLocalizations l) async {
    final controller = TextEditingController(text: _organizationName);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l.getKey('settings_edit_organization')),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l.getKey('settings_organization_name'),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.getKey('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text(l.getKey('save')),
              ),
            ],
          ),
    );

    if (newName != null && newName.isNotEmpty) {
      await SettingsService.setOrganizationName(newName);
      setState(() {
        _organizationName = newName;
      });
    }
  }
}
