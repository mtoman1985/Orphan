import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/registration_form.dart'; // your existing page
import 'models/child.dart'; // sample model (if available)

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

/// Minimal, manual localizations using the ARB files created under lib/l10n.
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
    },
    'ar': {
      'appTitle': 'ادارة الأيتام',
      'children': 'الأطفال',
      'register': 'تسجيل',
      'selectChildPrompt': 'اختر طفلاً لعرض التفاصيل',
      'childDetails': 'تفاصيل الطفل',
      'moreFields': 'المزيد من الحقول هنا...',
    },
    'tr': {
      'appTitle': 'Yetim Yönetimi',
      'children': 'Çocuklar',
      'register': 'Kayıt',
      'selectChildPrompt': 'Detayları görüntülemek için bir çocuk seçin',
      'childDetails': 'Çocuk Detayları',
      'moreFields': 'Daha fazla alan burada...',
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

  // Example in-memory list — replace with storage service
  final List<Map<String, String>> _children = List.generate(
    12,
    (i) => {
      'id': 'child-${i + 1}',
      'name': 'Child ${i + 1}',
      'dob': '2015-0${(i % 9) + 1}-01',
    },
  );

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrationForm()));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Responsive: show rail + list + details on wide screens
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
              itemBuilder:
                  (ctx) => const [
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
                onDestinationSelected:
                    (i) => setState(() => _selectedIndex = i),
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
            // Main content area
            Expanded(
              child: Row(
                children: [
                  // Left: list
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
                                  child: Text(
                                    '${AppLocalizations.of(context).get('children')} (${_children.length})',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _openRegister,
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).get('register'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: _children.length,
                              separatorBuilder:
                                  (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final c = _children[index];
                                final selected = c['id'] == _selectedChildId;
                                return ListTile(
                                  selected: selected,
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(c['name']!),
                                  subtitle: Text('DOB: ${c['dob']}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {
                                      // context menu example
                                      showModalBottomSheet(
                                        context: context,
                                        builder:
                                            (_) => SafeArea(
                                              child: Wrap(
                                                children: [
                                                  ListTile(
                                                    leading: Icon(Icons.edit),
                                                    title: Text('Edit'),
                                                    onTap: () {},
                                                  ),
                                                  ListTile(
                                                    leading: Icon(Icons.delete),
                                                    title: Text('Delete'),
                                                    onTap: () {},
                                                  ),
                                                ],
                                              ),
                                            ),
                                      );
                                    },
                                  ),
                                  onTap:
                                      () => setState(
                                        () => _selectedChildId = c['id'],
                                      ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right: details (visible on wide screens)
                  if (showDetailsPanel)
                    Flexible(
                      flex: 6,
                      child: Card(
                        margin: const EdgeInsets.all(12),
                        child:
                            _selectedChildId == null
                                ? Center(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).get('selectChildPrompt'),
                                  ),
                                )
                                : Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).get('childDetails'),
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.headlineSmall,
                                      ),
                                      const SizedBox(height: 12),
                                      Text('ID: $_selectedChildId'),
                                      const SizedBox(height: 8),
                                      // Replace with actual fields/photos
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).get('moreFields'),
                                      ),
                                    ],
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
