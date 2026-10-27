import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform, File, FileMode;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:orphan/l10n/app_localizations_extension.dart';
import 'package:window_manager/window_manager.dart';
import 'package:animate_do/animate_do.dart';
import 'models/child.dart';
import 'services/storage_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/settings_service.dart';
import 'pages/registration/registration_form.dart';
import 'pages/main/children_page.dart';
import 'pages/main/sponsors_page.dart';
import 'pages/utilities/cloud_sync_page.dart';
import 'pages/reports/reports_page.dart';
import 'pages/settings/settings_page.dart';
import 'theme.dart';
import 'package:orphan/l10n/app_localizations.dart';
import 'utils/responsive_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/main/search_results_page.dart';
import 'services/firebase_sync_service.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/auth/login_page.dart';
import 'pages/admin/user_management_page.dart';
import 'pages/finance/finance_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('Firebase initialization failed: $e');
    // Write to a local file to catch crashes on Windows
    if (!kIsWeb) {
      File('crash_log.txt').writeAsStringSync('Firebase Error: $e\n$stack');
    }
  }

  try {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      await windowManager.ensureInitialized();

      // تحديد أبعاد النافذة الأولية مع إظهار أزرار التحكم
      const windowOptions = WindowOptions(
        size: Size(1400, 900),
        center: true,
        backgroundColor: Colors.white,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        windowButtonVisibility: true,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        await Future.delayed(const Duration(milliseconds: 500));
        await windowManager.maximize();
        await windowManager.setMinimumSize(const Size(1200, 700));
      });
    }
  } catch (e, stack) {
    if (!kIsWeb) {
      File(
        'crash_log.txt',
      ).writeAsStringSync('Startup Error: $e\n$stack', mode: FileMode.append);
    }
  }

  runApp(const OrphanDesktopApp());
}

class _SidebarItem extends StatefulWidget {
  final int index;
  final int selectedIndex;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SidebarItem({
    Key? key,
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.index == widget.selectedIndex;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) {
        if (!selected) _hoverController.forward();
      },
      onExit: (_) {
        if (!selected) _hoverController.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: FadeTransition(
          opacity:
              selected ? const AlwaysStoppedAnimation(1.0) : _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: selected ? 1.0 : 0.0,
                end: selected ? 1.0 : 0.0,
              ),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        selected
                            ? Border.all(
                              color: theme.colorScheme.primary.withOpacity(
                                0.3 + (0.2 * value),
                              ),
                              width: 1.5,
                            )
                            : null,
                    boxShadow:
                        selected && value > 0.5
                            ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1 * value,
                                ),
                                blurRadius: 8 * value,
                                spreadRadius: 0,
                              ),
                            ]
                            : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? theme.colorScheme.primary.withOpacity(0.15)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color:
                              selected
                                  ? theme.colorScheme.primary
                                  : Colors.grey[600],
                        ),
                      ),
                      title: Text(
                        widget.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color:
                              selected
                                  ? theme.colorScheme.primary
                                  : Colors.grey[700],
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class OrphanDesktopApp extends StatefulWidget {
  const OrphanDesktopApp({super.key});

  @override
  State<OrphanDesktopApp> createState() => _OrphanDesktopAppState();
}

enum StorageBackend { local, sqlite, api }

class _OrphanDesktopAppState extends State<OrphanDesktopApp> {
  Locale _locale = const Locale('ar');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      await SettingsService.init();

      // Initialize Auth
      await AuthService().init();

      // استخدام لغة التقارير كلغة للواجهة
      final savedLangCode = await SettingsService.getDefaultReportLanguage();
      setState(() {
        _locale = Locale(savedLangCode);
        _isLoading = false;
      });

      // NEW: Sync data from Firebase on Web or Windows startup (non-blocking - in background)
      bool isWindows = !kIsWeb && Platform.isWindows;
      if (kIsWeb || isWindows) {
        debugPrint('Startup: Syncing all data from Firebase in background...');
        // تشغيل بدون await - لا تحجب عرض الواجهة
        FirebaseSyncService()
            .integrateAllData()
            .then((_) {
              debugPrint('Startup: Sync complete.');
            })
            .catchError((e) {
              debugPrint('Startup Error: $e');
            });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setLocale(Locale l) async {
    // حفظ لغة الواجهة في إعداد لغة التقارير
    await SettingsService.setDefaultReportLanguage(l.languageCode);
    setState(() {
      _locale = l;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // تحديد اتجاه النص بناءً على اللغة
    final isArabic = _locale.languageCode == 'ar';

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Orphan Management (Desktop)',
        theme: buildAppTheme(),
        locale: _locale,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('tr')],
        builder: (context, child) {
          return Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox(),
          );
        },
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (!auth.isAuthenticated) {
              return const LoginPage();
            }
            return DesktopShell(
              currentLocale: _locale,
              onLocaleChange: _setLocale,
            );
          },
        ),
      ),
    );
  }
}

class DesktopShell extends StatefulWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChange;

  const DesktopShell({
    super.key,
    required this.currentLocale,
    required this.onLocaleChange,
  });

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 0;
  bool _showSidebar = true;
  final _searchController = TextEditingController();

  final List<Child> _children = [];
  final StorageService _storage = StorageService();
  late final CloudSyncService _cloudSync;

  @override
  void initState() {
    super.initState();
    _cloudSync = CloudSyncService();
    _loadChildren();
    _checkAutoBackup();

    // Listen for background sync completion to refresh the list
    FirebaseSyncService().syncCompleted.addListener(() {
      if (mounted) _loadChildren();
    });
  }

  Future<void> _checkAutoBackup() async {
    final isAutoEnabled = await SettingsService.getAutoBackup();
    if (!isAutoEnabled) return;

    final lastBackup = await SettingsService.getLastBackupTime();
    final interval = await SettingsService.getBackupInterval();

    if (lastBackup == null ||
        DateTime.now().difference(lastBackup).inDays >= interval) {
      debugPrint('Auto-Backup: Interval reached. Starting background sync...');

      // We run this in background after a short delay to not block UI startup
      Future.delayed(const Duration(seconds: 10), () async {
        try {
          await FirebaseSyncService().integrateAllData();
          await SettingsService.setLastBackupTime(DateTime.now());
          debugPrint('Auto-Backup: Completed successfully.');
        } catch (e) {
          debugPrint('Auto-Backup Error: $e');
        }
      });
    }
  }

  Future<void> _loadChildren() async {
    final children = await _storage.listChildren();
    setState(() {
      _children.clear();
      _children.addAll(children);
    });
  }

  void _openRegister() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrationForm()));
    _loadChildren();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => SearchResultsPage(
              searchQuery: query.trim(),
              onOpenChild: _openChildFromSearch,
            ),
      ),
    );
  }

  void _openChildFromSearch(Child child) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RegistrationForm(child: child)));
    _loadChildren();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    bool isWide = width >= 900;

    Widget sidebar = FadeInLeft(
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar Header with Logo
              FadeInDown(
                duration: const Duration(milliseconds: 700),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stack) =>
                                  const FlutterLogo(size: 42),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeInRight(
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                AppLocalizations.of(context)!.sidebar_title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            FadeInRight(
                              duration: const Duration(milliseconds: 900),
                              child: Text(
                                'v1.0.0',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Navigation Items with Staggered Animation
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    SlideInLeft(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 100),
                      child: _SidebarItem(
                        index: 2,
                        selectedIndex: _selectedIndex,
                        label:
                            AppLocalizations.of(
                              context,
                            )!.sidebar_create_profile,
                        icon: Icons.person_add,
                        onTap:
                            () => setState(() {
                              _selectedIndex = 2;
                              _showSidebar = false;
                            }),
                      ),
                    ),
                    SlideInLeft(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 200),
                      child: _SidebarItem(
                        index: 0,
                        selectedIndex: _selectedIndex,
                        label: AppLocalizations.of(context)!.children,
                        icon: Icons.list,
                        onTap:
                            () => setState(() {
                              _selectedIndex = 0;
                              _showSidebar = false;
                            }),
                      ),
                    ),
                    SlideInLeft(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 300),
                      child: _SidebarItem(
                        index: 3,
                        selectedIndex: _selectedIndex,
                        label: AppLocalizations.of(context)!.sidebar_sponsors,
                        icon: Icons.volunteer_activism,
                        onTap:
                            () => setState(() {
                              _selectedIndex = 3;
                              _showSidebar = false;
                            }),
                      ),
                    ),
                    // التقارير
                    SlideInLeft(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 350),
                      child: _SidebarItem(
                        index: 9,
                        selectedIndex: _selectedIndex,
                        label: AppLocalizations.of(context)!.sidebar_reports,
                        icon: Icons.assessment,
                        onTap:
                            () => setState(() {
                              _selectedIndex = 9;
                              _showSidebar = false;
                            }),
                      ),
                    ),
                    // المالية
                    SlideInLeft(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 375),
                      child: _SidebarItem(
                        index: 11,
                        selectedIndex: _selectedIndex,
                        label: AppLocalizations.of(
                          context,
                        )!.get('financial_system'),
                        icon: Icons.account_balance_wallet,
                        onTap:
                            () => setState(() {
                              _selectedIndex = 11;
                              _showSidebar = false;
                            }),
                      ),
                    ),
                    // Cloud Sync
                    SlideInLeft(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 400),
                      child: _SidebarItem(
                        index: 8,
                        selectedIndex: _selectedIndex,
                        label: AppLocalizations.of(context)!.sidebar_cloud_sync,
                        icon: Icons.cloud_sync,
                        onTap:
                            () => setState(() {
                              _selectedIndex = 8;
                              _showSidebar = false;
                            }),
                      ),
                    ),
                    SlideInLeft(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 500),
                      child: _SidebarItem(
                        index: 6,
                        selectedIndex: _selectedIndex,
                        label: AppLocalizations.of(context)!.sidebar_system,
                        icon: Icons.settings,
                        onTap:
                            () => setState(() {
                              _selectedIndex = 6;
                              _showSidebar = false;
                            }),
                      ),
                    ),
                    const Divider(),
                    if (Provider.of<AuthService>(
                      context,
                      listen: false,
                    ).isAdmin)
                      SlideInLeft(
                        duration: const Duration(milliseconds: 700),
                        delay: const Duration(milliseconds: 600),
                        child: _SidebarItem(
                          index: 10,
                          selectedIndex: _selectedIndex,
                          label: AppLocalizations.of(
                            context,
                          )!.get('user_management'),
                          icon: Icons.admin_panel_settings,
                          onTap:
                              () => setState(() {
                                _selectedIndex = 10;
                                _showSidebar = false;
                              }),
                        ),
                      ),
                    SlideInLeft(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 700),
                      child: _SidebarItem(
                        index: -1,
                        selectedIndex: _selectedIndex,
                        label: AppLocalizations.of(context)!.get('logout'),
                        icon: Icons.logout,
                        onTap: () {
                          Provider.of<AuthService>(
                            context,
                            listen: false,
                          ).logout();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget topBar = FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Builder(
        builder: (context) {
          final responsive = context.responsive;
          final theme = Theme.of(context);
          final horizontalPadding = responsive.isSmallScreen ? 12.0 : 20.0;
          final searchFieldWidth = responsive.widthPercent(35);

          return Container(
            height: 72,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Menu button or sidebar toggle
                if (!isWide)
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    iconSize: 24,
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip: 'Menu',
                  )
                else
                  Tooltip(
                    message: _showSidebar ? 'Hide sidebar' : 'Show sidebar',
                    child: IconButton(
                      icon: Icon(
                        _showSidebar
                            ? Icons.menu_open_rounded
                            : Icons.menu_rounded,
                      ),
                      onPressed:
                          () => setState(() => _showSidebar = !_showSidebar),
                    ),
                  ),

                // Search field
                Container(
                  width: searchFieldWidth,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 0.5),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHint,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[600],
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      isDense: true,
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    style: theme.textTheme.bodySmall,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: _performSearch,
                  ),
                ),

                const SizedBox(width: 8),

                // Search button
                ElevatedButton.icon(
                  onPressed: () => _performSearch(_searchController.text),
                  icon: const Icon(Icons.search, size: 18),
                  label: Text(AppLocalizations.of(context)!.search_label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const Spacer(),

                // Language selector with modern design
                PopupMenuButton<Locale>(
                  tooltip: 'Change language',
                  icon: Icon(Icons.language_rounded, color: Colors.grey[700]),
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder:
                      (ctx) => [
                        PopupMenuItem(
                          value: const Locale('en'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('🇬🇧 ', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text('English'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: const Locale('ar'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('🇸🇦 ', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text('العربية'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: const Locale('tr'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('🇹🇷 ', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text('Türkçe'),
                            ],
                          ),
                        ),
                      ],
                  onSelected: (l) => widget.onLocaleChange(l),
                ),

                const SizedBox(width: 8),

                // User profile avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.currentLocale.languageCode.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    Widget content;
    switch (_selectedIndex) {
      case 3:
        content = SponsorsPage(onOpenCreateSponsor: _openRegister);
        break;
      case 2:
        content = const RegistrationForm();
        break;
      case 6:
        content = SettingsPage(
          currentLocale: widget.currentLocale,
          onLocaleChange: widget.onLocaleChange,
        );
        break;
      case 8:
        content = CloudSyncPage(cloudSync: _cloudSync);
        break;
      case 9:
        content = const ReportsPage();
        break;
      case 10:
        content = const UserManagementPage();
        break;
      case 11:
        content = const FinancePage();
        break;
      case 0:
      default:
        content = ChildrenPage(onOpenCreate: _openRegister);
        break;
    }

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            NewIntent(),
      },
      child: Scaffold(
        drawer: isWide ? null : Drawer(child: sidebar),
        body: Row(
          children: [
            if (isWide)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _showSidebar ? 260.0 : 36.0,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topLeft,
                    widthFactor: 1.0,
                    child:
                        _showSidebar
                            ? sidebar
                            : Container(
                              width: 36,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  tooltip:
                                      AppLocalizations.of(
                                        context,
                                      )!.sidebar_title,
                                  onPressed:
                                      () => setState(() => _showSidebar = true),
                                ),
                              ),
                            ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  topBar,
                  Expanded(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: content,
                          ),
                        ),
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
}

class NewIntent extends Intent {}
