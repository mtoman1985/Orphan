import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/registration_form.dart';
import 'pages/sponsors_page.dart';
import 'models/child.dart';
import 'services/database_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrphanDesktopApp());
}

class OrphanDesktopApp extends StatelessWidget {
  const OrphanDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orphan Management (Desktop)',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      localizationsDelegates: [
        const _AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('tr')],
      home: const DesktopShell(),
    );
  }
}

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Orphan Management',
      'children': 'Children',
      'register': 'Register',
      'selectChildPrompt': 'Select a child to view details',
      'childDetails': 'Child Details',
      'moreFields': 'More fields here...',
      'loading': 'Loading...',
      'error': 'Error loading data',
      'noChildren': 'No children found',
      'edit': 'Edit',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'deleteConfirm': 'Are you sure you want to delete this child?',
    },
    'ar': {
      'appTitle': 'ادارة الأيتام',
      'children': 'الأطفال',
      'register': 'تسجيل',
      'selectChildPrompt': 'اختر طفلاً لعرض التفاصيل',
      'childDetails': 'تفاصيل الطفل',
      'moreFields': 'المزيد من الحقول هنا...',
      'loading': 'جاري التحميل...',
      'error': 'خطأ في تحميل البيانات',
      'noChildren': 'لم يتم العثور على أطفال',
      'edit': 'تعديل',
      'delete': 'حذف',
      'confirm': 'تأكيد',
      'cancel': 'إلغاء',
      'deleteConfirm': 'هل أنت متأكد من رغبتك في حذف هذا الطفل؟',
    },
    'tr': {
      'appTitle': 'Yetim Yönetimi',
      'children': 'Çocuklar',
      'register': 'Kayıt',
      'selectChildPrompt': 'Detayları görüntülemek için bir çocuk seçin',
      'childDetails': 'Çocuk Detayları',
      'moreFields': 'Daha fazla alan burada...',
      'loading': 'Yükleniyor...',
      'error': 'Veri yüklenirken hata oluştu',
      'noChildren': 'Çocuk bulunamadı',
      'edit': 'Düzenle',
      'delete': 'Sil',
      'confirm': 'Onayla',
      'cancel': 'İptal',
      'deleteConfirm': 'Bu çocuğu silmek istediğinizden emin misiniz?',
    },
  };

  String get(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']![key] ?? key;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 0;
  String? _selectedChildId;
  late DatabaseService _dbService;
  late Future<List<Child>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService();
    _childrenFuture = _dbService.getAllChildren();
  }

  void _openRegister() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegistrationForm()))
        .then((_) {
      setState(() {
        _childrenFuture = _dbService.getAllChildren();
      });
    });
  }

  void _deleteChild(String childId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).get('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.deleteChild(childId);
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _childrenFuture = _dbService.getAllChildren();
                  _selectedChildId = null;
                });
              }
            },
            child: Text(AppLocalizations.of(context).get('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showDetailsPanel = width >= 1000;
    final showNavRail = width >= 600;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const ActivateIntent(),
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).get('appTitle')),
          actions: [
            IconButton(
              onPressed: _openRegister,
              icon: const Icon(Icons.person_add),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {},
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: 'import',
                  child: Text('Import Data...'),
                ),
                PopupMenuItem(value: 'settings', child: Text('Settings')),
              ],
            ),
          ],
        ),
        body: Row(
          children: [
            if (showNavRail)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                labelType: NavigationRailLabelType.selected,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.list),
                    label: Text(AppLocalizations.of(context).get('children')),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.report),
                    label: const Text('Reports'),
                  ),
                ],
              ),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    flex: showDetailsPanel ? 4 : 1,
                    child: Card(
                      margin: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FutureBuilder<List<Child>>(
                                    future: _childrenFuture,
                                    builder: (context, snapshot) {
                                      final count = snapshot.data?.length ?? 0;
                                      return Text(
                                        '${AppLocalizations.of(context).get('children')} ($count)',
                                        style:
                                            Theme.of(context).textTheme.titleLarge,
                                      );
                                    },
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _openRegister,
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    AppLocalizations.of(context).get('register'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: FutureBuilder<List<Child>>(
                              future: _childrenFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .get('loading'),
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .get('error'),
                                    ),
                                  );
                                }

                                final children = snapshot.data ?? [];

                                if (children.isEmpty) {
                                  return Center(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .get('noChildren'),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: children.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final c = children[index];
                                    final selected = c.id == _selectedChildId;
                                    return ListTile(
                                      selected: selected,
                                      leading: CircleAvatar(
                                        child: Text('${index + 1}'),
                                      ),
                                      title: Text(c.fullName),
                                      subtitle: Text('ID: ${c.childIdNumber}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.more_vert),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (_) => SafeArea(
                                              child: Wrap(
                                                children: [
                                                  ListTile(
                                                    leading:
                                                        const Icon(Icons.edit),
                                                    title: Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .get('edit'),
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                        Icons.delete),
                                                    title: Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .get('delete'),
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _deleteChild(c.id);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      onTap: () => setState(
                                        () => _selectedChildId = c.id,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showDetailsPanel)
                    Flexible(
                      flex: 6,
                      child: Card(
                        margin: const EdgeInsets.all(12),
                        child: _selectedChildId == null
                            ? Center(
                                child: Text(
                                  AppLocalizations.of(context)
                                      .get('selectChildPrompt'),
                                ),
                              )
                            : FutureBuilder<Child?>(
                                future:
                                    _dbService.getChild(_selectedChildId!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .get('loading'),
                                      ),
                                    );
                                  }

                                  if (!snapshot.hasData) {
                                    return Center(
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .get('error'),
                                      ),
                                    );
                                  }

                                  final child = snapshot.data!;
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Text(
                                                AppLocalizations.of(context)
                                                    .get('childDetails'),
                                                style: Theme.of(context)
                                                    .textTheme.headlineSmall,
                                              ),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          SponsorsPage(
                                                            childId: child.id,
                                                          ),
                                                    ),
                                                  ).then((_) {
                                                    setState(() {
                                                      _childrenFuture =
                                                          _dbService
                                                              .getAllChildren();
                                                    });
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.person_add),
                                                label: const Text(
                                                    'Link Sponsor'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                              'Full Name: ${child.fullName}'),
                                          const SizedBox(height: 8),
                                          Text('ID: ${child.childIdNumber}'),
                                          const SizedBox(height: 8),
                                          Text(
                                              'DOB: ${child.dateOfBirth?.toString() ?? 'N/A'}'),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Father: ${child.fatherName}'),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Mother: ${child.motherName}'),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Health: ${child.healthStatus}'),
                                          const SizedBox(height: 16),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Sponsor Information',
                                            style: Theme.of(context)
                                                .textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          FutureBuilder<dynamic>(
                                            future: _dbService
                                                .getChildSponsor(child.id),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Text(
                                                    'Loading...');
                                              }

                                              if (snapshot.data == null) {
                                                return const Text(
                                                  'No sponsor linked',
                                                  style: TextStyle(
                                                    fontStyle:
                                                        FontStyle.italic,
                                                  ),
                                                );
                                              }

                                              final sponsor =
                                                  snapshot.data;
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                      'Name: ${sponsor.name}'),
                                                  const SizedBox(height: 4),
                                                  if (sponsor.email != null)
                                                    Text(
                                                        'Email: ${sponsor.email}'),
                                                  if (sponsor.phone != null)
                                                    const SizedBox(height: 4),
                                                  if (sponsor.phone != null)
                                                    Text(
                                                        'Phone: ${sponsor.phone}'),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                      'Monthly Amount: \$${sponsor.amount.toStringAsFixed(2)}'),
                                                  const SizedBox(height: 12),
                                                  ElevatedButton.icon(
                                                    onPressed: () async {
                                                      await _dbService
                                                          .unlinkSponsorFromChild(
                                                            child.id,
                                                          );
                                                      if (mounted) {
                                                        setState(() {
                                                          _childrenFuture =
                                                              _dbService
                                                                  .getAllChildren();
                                                        });
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete),
                                                    label: const Text(
                                                        'Unlink Sponsor'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
