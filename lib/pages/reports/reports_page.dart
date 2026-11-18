import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:animate_do/animate_do.dart';
import '../../services/sqlite_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../models/child.dart';
import '../../models/sponsor.dart';
import '../../models/payment.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';
import 'pdf_report.dart';
import 'sponsor_report.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final SqliteService _dbService = SqliteService();
  String _selectedReportType = 'orphans';
  bool _isLoading = false;

  // Filter options
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DateTime? _startDate;
  DateTime? _endDate;
  String _dateFilterMode = 'monthly'; // 'monthly', 'range', 'yearly', 'none'
  String _selectedFilterSubMode =
      'monthly'; // 'monthly', 'range', 'yearly' (when dateFilterMode is 'flexible')

  String? _selectedPersonId;
  String? _selectedPersonName;

  List<Child> _children = [];
  List<Sponsor> _sponsors = [];
  bool _dataLoaded = false;

  // Columns selection for list reports
  List<String> _selectedColumns = ['child_name', 'child_id_label', 'age_label'];

  final List<String> _defaultOrphanColumns = [
    'child_name',
    'child_id_label',
    'national_id',
    'age_label',
    'gender',
    'father_status',
    'mother_status',
    'country_label',
    'city',
    'education_level_colon',
    'health_status_label',
    'report_sponsor',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final isWeb = kIsWeb;
      List<Child> children = [];
      List<Sponsor> sponsors = [];

      if (isWeb) {
        // Web: Firebase only
        children = await FirebaseSyncService().getAllChildrenFromFirebase();
        sponsors = await FirebaseSyncService().getAllSponsorsFromFirebase();
      } else {
        // Windows: SQLite first, then Firebase if empty
        children = await _dbService.listChildren();
        sponsors = await _dbService.listSponsors();

        if (children.isEmpty) {
          children = await FirebaseSyncService().getAllChildrenFromFirebase();
        }
        if (sponsors.isEmpty) {
          sponsors = await FirebaseSyncService().getAllSponsorsFromFirebase();
        }
      }

      setState(() {
        _children = children;
        _sponsors = sponsors;
        _dataLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading data for reports: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final l = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                [
                  // Header مطابق لصفحة الأيتام
                  _buildHeader(theme),
                  const SizedBox(height: 15),
                  // Category 1: Orphan Specific Reports
                  _buildCategoryCard(
                    l.get('report_single_orphan_category'),
                    Icons.person,
                    [
                      _buildReportActionChip(
                        'orphan_financial_report',
                        l.get('orphan_financial_report'),
                        Icons.account_balance_wallet,
                        theme,
                        dateMode: 'flexible',
                        needsPerson: true,
                      ),
                    ],
                    theme,
                  ),
                  const SizedBox(height: 15),
                  // Category 2: General Orphans Reports
                  _buildCategoryCard(
                    l.get('report_general_orphans_category'),
                    Icons.child_care,
                    [
                      _buildReportActionChip(
                        'all_orphans',
                        l.get('report_type_orphans'),
                        Icons.groups,
                        theme,
                        dateMode: 'none',
                      ),
                      _buildReportActionChip(
                        'sponsored_orphans',
                        l.get('report_sponsored_orphans'),
                        Icons.volunteer_activism,
                        theme,
                        dateMode: 'none',
                      ),
                      _buildReportActionChip(
                        'registered_unsponsored',
                        l.get('report_registered_unsponsored'),
                        Icons.person_search,
                        theme,
                        dateMode: 'none',
                      ),
                      _buildReportActionChip(
                        'unregistered_unsponsored',
                        l.get('report_unregistered_unsponsored'),
                        Icons.people_outline,
                        theme,
                        dateMode: 'none',
                      ),
                    ],
                    theme,
                  ),
                  const SizedBox(height: 15),
                  // Category 3: Sponsor Reports
                  _buildCategoryCard(
                    l.get('report_sponsors_category'),
                    Icons.volunteer_activism,
                    [
                      _buildReportActionChip(
                        'sponsor_summary',
                        l.get('report_sponsor_summary'),
                        Icons.summarize,
                        theme,
                        needsPerson: true,
                        dateMode: 'flexible',
                      ),
                      _buildReportActionChip(
                        'sponsor_detailed',
                        l.get('report_sponsor_detailed'),
                        Icons.list_alt,
                        theme,
                        needsPerson: true,
                        dateMode: 'flexible',
                      ),
                    ],
                    theme,
                  ),
                  const SizedBox(height: 15),
                  // Filters Section (Date and Person)
                  _buildFiltersSection(theme),
                  const SizedBox(height: 15),
                  // Columns selection (only for orphan listing reports)
                  if (_isListingReport()) ...[
                    _buildColumnSelectionSection(theme),
                    const SizedBox(height: 15),
                  ],
                  // Generate Report Button
                  _buildGenerateButton(theme),
                  const SizedBox(height: 15),
                ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
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
                Icons.assessment,
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
                    l.reports_page_title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.reports_page_description,
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

  Widget _buildCategoryCard(
    String title,
    IconData icon,
    List<Widget> actions,
    ThemeData theme,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(spacing: 12, runSpacing: 12, children: actions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportActionChip(
    String type,
    String label,
    IconData icon,
    ThemeData theme, {
    bool needsPerson = false,
    String dateMode = 'monthly',
  }) {
    final isSelected = _selectedReportType == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedReportType = type;
          _dateFilterMode = dateMode;
          // Reset person if not needed
          if (!needsPerson) {
            _selectedPersonId = null;
            _selectedPersonName = null;
          }
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    if (_dateFilterMode == 'none' && !_needsPersonFilter())
      return const SizedBox.shrink();

    return FadeInUp(
      duration: const Duration(milliseconds: 750),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.get('report_options'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_dateFilterMode == 'flexible')
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'monthly',
                        label: Text(l.get('monthly_label')),
                      ),
                      ButtonSegment(
                        value: 'yearly',
                        label: Text(l.get('yearly_label')),
                      ),
                      ButtonSegment(
                        value: 'range',
                        label: Text(l.get('range_label')),
                      ),
                    ],
                    selected: {_selectedFilterSubMode},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedFilterSubMode = newSelection.first;
                      });
                    },
                  ),
                ),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Monthly filter: Year and Month
                  if (_dateFilterMode != 'none' &&
                      _selectedFilterSubMode == 'monthly') ...[
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          labelText: l.get('year_label'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: List.generate(10, (index) {
                          final year = DateTime.now().year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                        onChanged:
                            (value) => setState(() => _selectedYear = value!),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: l.get('month_label'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          for (int i = 1; i <= 12; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text(_getMonthName(i, l)),
                            ),
                        ],
                        onChanged:
                            (value) => setState(() => _selectedMonth = value!),
                      ),
                    ),
                  ],

                  // Yearly filter: Year only
                  if (_dateFilterMode != 'none' &&
                      _selectedFilterSubMode == 'yearly')
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          labelText: l.get('year_label'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: List.generate(10, (index) {
                          final year = DateTime.now().year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                        onChanged:
                            (value) => setState(() => _selectedYear = value!),
                      ),
                    ),

                  // Range filter: From and To dates
                  if (_dateFilterMode != 'none' &&
                      _selectedFilterSubMode == 'range')
                    _buildDateRangeFilter(l, theme),

                  // Person selection
                  if (_needsPersonFilter())
                    SizedBox(
                      width: 300,
                      child: InkWell(
                        onTap: _selectPerson,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: _getPersonLabel(l),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon:
                                _selectedPersonId != null
                                    ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed:
                                          () => setState(() {
                                            _selectedPersonId = null;
                                            _selectedPersonName = null;
                                          }),
                                    )
                                    : null,
                          ),
                          child: Text(
                            _selectedPersonName ?? l.get('select_button'),
                            style: TextStyle(
                              color:
                                  _selectedPersonId != null
                                      ? theme.colorScheme.onSurface
                                      : theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isListingReport() {
    return _selectedReportType == 'all_orphans' ||
        _selectedReportType == 'sponsored_orphans' ||
        _selectedReportType == 'registered_unsponsored';
  }

  Widget _buildColumnSelectionSection(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.view_column, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l.get('select_columns_to_show'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.select_all, size: 18),
                        label: Text(
                          l.get('select_all'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedColumns = List.from(_defaultOrphanColumns);
                          });
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.deselect, size: 18),
                        label: Text(
                          l.getKey('clear_all'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            // Keep at least name
                            _selectedColumns = ['child_name'];
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _defaultOrphanColumns.map((columnKey) {
                      final isSelected = _selectedColumns.contains(columnKey);
                      String label = l.get(columnKey);
                      // Clean label if it has colon
                      if (label.endsWith(':')) {
                        label = label.substring(0, label.length - 1);
                      }

                      return FilterChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedColumns.add(columnKey);
                            } else {
                              // Prevent removing all columns
                              if (_selectedColumns.length > 1) {
                                _selectedColumns.remove(columnKey);
                              }
                            }
                          });
                        },
                        selectedColor: theme.colorScheme.primary,
                        checkmarkColor: Colors.white,
                        backgroundColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade300,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter(AppLocalizations l, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDateField(
          l.get('from_label'),
          _startDate,
          (date) => setState(() => _startDate = date),
          theme,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('-'),
        ),
        _buildDateField(
          l.get('to_label'),
          _endDate,
          (date) => setState(() => _endDate = date),
          theme,
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime) onSelected,
    ThemeData theme,
  ) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) onSelected(date);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.calendar_today, size: 16),
          ),
          child: Text(
            value != null
                ? value.toString().split(' ').first
                : l.get('date_placeholder'),
            style: TextStyle(
              fontSize: 14,
              color:
                  value != null ? theme.colorScheme.onSurface : theme.hintColor,
            ),
          ),
        ),
      ),
    );
  }

  bool _needsPersonFilter() {
    return _selectedReportType == 'sponsor_summary' ||
        _selectedReportType == 'sponsor_detailed' ||
        _selectedReportType == 'individual_orphan_form' ||
        _selectedReportType == 'orphan_form' ||
        _selectedReportType == 'orphan_financial_report';
  }

  String _getPersonLabel(AppLocalizations l) {
    if (_selectedReportType == 'individual_orphan_form' ||
        _selectedReportType == 'orphan_form' ||
        _selectedReportType == 'orphan_financial_report') {
      return l.get('select_orphan');
    }
    return l.get('select_sponsor');
  }

  Future<void> _selectPerson() async {
    if (_selectedReportType == 'individual_orphan_form' ||
        _selectedReportType == 'orphan_form' ||
        _selectedReportType == 'orphan_financial_report') {
      await _selectOrphan();
    } else if (_selectedReportType == 'sponsor_summary' ||
        _selectedReportType == 'sponsor_detailed') {
      await _selectSponsor();
    }
  }

  String _getMonthName(int month, AppLocalizations l) {
    return l.get('month_${month.toString().padLeft(2, '0')}');
  }

  Future<void> _selectOrphan() async {
    final l = AppLocalizations.of(context)!;
    final selected = await showDialog<Child>(
      context: context,
      builder:
          (context) => _PersonSelectionDialog(
            title: l.get('select_orphan'),
            items: _children,
            itemBuilder:
                (child) => ListTile(
                  leading: CircleAvatar(child: Text(child.fullName[0])),
                  title: Text(child.fullName),
                  subtitle: Text('${l.get('code_label')}: ${child.id}'),
                ),
          ),
    );

    if (selected != null) {
      setState(() {
        _selectedPersonId = selected.id;
        _selectedPersonName = selected.fullName;
      });
    }
  }

  Future<void> _selectSponsor() async {
    final l = AppLocalizations.of(context)!;
    final selected = await showDialog<Sponsor>(
      context: context,
      builder:
          (context) => _PersonSelectionDialog(
            title: l.get('select_sponsor'),
            items: _sponsors,
            itemBuilder:
                (sponsor) => ListTile(
                  leading: CircleAvatar(child: Text(sponsor.name[0])),
                  title: Text(sponsor.name),
                  subtitle: Text(
                    '${l.get('amount_label')}: ${sponsor.amount} ${sponsor.currency}',
                  ),
                ),
          ),
    );

    if (selected != null) {
      setState(() {
        // استخدام id إذا كان موجوداً، وإلا استخدام الاسم كمعرف
        _selectedPersonId = selected.id ?? selected.name;
        _selectedPersonName = selected.name;
      });
    }
  }

  Widget _buildGenerateButton(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _generateReport,
          icon:
              _isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Icon(Icons.picture_as_pdf, size: 24),
          label: Text(
            _isLoading
                ? l.get('generating_report')
                : l.get('generate_and_print'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  IconData _getReportIcon() {
    switch (_selectedReportType) {
      case 'individual_orphan_form':
        return Icons.assignment_ind;
      case 'orphan_form':
        return Icons.description;
      case 'orphan_financial_report':
        return Icons.account_balance_wallet;
      case 'all_orphans':
        return Icons.groups;
      case 'sponsored_orphans':
        return Icons.volunteer_activism;
      case 'registered_unsponsored':
        return Icons.person_search;
      case 'unregistered_unsponsored':
        return Icons.people_outline;
      case 'sponsor_summary':
        return Icons.summarize;
      case 'sponsor_detailed':
        return Icons.list_alt;
      default:
        return Icons.description;
    }
  }

  String _getReportTitle(AppLocalizations l) {
    switch (_selectedReportType) {
      case 'individual_orphan_form':
        return l.get('report_type_single_orphan');
      case 'orphan_form':
        return l.get('orphan_form_title');
      case 'orphan_financial_report':
        return l.get('orphan_financial_report');
      case 'all_orphans':
        return l.get('report_type_orphans');
      case 'sponsored_orphans':
        return l.get('report_sponsored_orphans');
      case 'registered_unsponsored':
        return l.get('report_registered_unsponsored');
      case 'unregistered_unsponsored':
        return l.get('report_unregistered_unsponsored');
      case 'sponsor_summary':
        return l.get('report_sponsor_summary');
      case 'sponsor_detailed':
        return l.get('report_sponsor_detailed');
      default:
        return '';
    }
  }

  String _getReportDescription(AppLocalizations l) {
    switch (_selectedReportType) {
      case 'individual_orphan_form':
        return l.get('complete_orphan_report');
      case 'orphan_form':
        return l.get('orphan_form_description');
      case 'orphan_financial_report':
        return l.get('orphan_financial_report_desc');
      case 'all_orphans':
        return l.get('complete_orphans_list_title');
      case 'sponsored_orphans':
        return l.get('report_sponsored_orphans_desc');
      case 'registered_unsponsored':
        return l.get('unsponsored_orphans_list');
      case 'unregistered_unsponsored':
        return l.get('report_unregistered_unsponsored_desc');
      case 'sponsor_summary':
        return l.get('report_sponsor_summary_desc');
      case 'sponsor_detailed':
        return l.get('report_sponsor_detailed_desc');
      default:
        return '';
    }
  }

  List<String> _getReportContents(AppLocalizations l) {
    switch (_selectedReportType) {
      case 'individual_orphan_form':
        return [
          l.get('personal_info'),
          l.get('health_info_title'),
          l.get('education_info_title'),
          l.get('sponsorship_info'),
        ];
      case 'orphan_form':
        return [
          l.get('personal_info'),
          l.get('health_info_title'),
          l.get('education_info_title'),
          l.get('sponsorship_info'),
        ];
      case 'orphan_financial_report':
        return [
          l.get('personal_info'),
          l.get('health_info_title'),
          l.get('education_info_title'),
          l.get('sponsorship_info'),
          l.get('received_payments_table'),
        ];
      case 'all_orphans':
      case 'sponsored_orphans':
      case 'registered_unsponsored':
        return [
          l.get('personal_info'),
          l.get('contact_information'),
          l.get('sponsorship_status'),
        ];
      case 'unregistered_unsponsored':
        return [l.get('siblings_data'), l.get('guardian_info')];
      case 'sponsor_summary':
        return [
          l.get('sponsor_info'),
          l.get('total_orphans_count'),
          l.get('total_payments_summary'),
        ];
      case 'sponsor_detailed':
        return [
          l.get('sponsor_info'),
          l.get('detailed_payments_table'),
          l.get('orphans_details_list'),
        ];
      default:
        return [];
    }
  }

  Future<void> _generateReport() async {
    final l = AppLocalizations.of(context)!;
    // Validation
    if (_needsPersonFilter() && _selectedPersonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.get('please_select_person_first')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // استخدام لغة البرنامج الحالية للتقارير
      final locale = Localizations.localeOf(context);

      switch (_selectedReportType) {
        case 'individual_orphan_form':
          await _generateSingleOrphanReport(locale);
          break;
        case 'orphan_form':
          await _generateOrphanForm(locale);
          break;
        case 'orphan_financial_report':
          await _generateOrphanFinancialReport(locale);
          break;
        case 'all_orphans':
          await _generateAllOrphansReport(locale);
          break;
        case 'sponsored_orphans':
          await _generateSponsoredOrphansReport(locale);
          break;
        case 'registered_unsponsored':
          await _generateUnsponsoredReport(locale);
          break;
        case 'unregistered_unsponsored':
          await _generateUnregisteredUnsponsoredReport(locale);
          break;
        case 'sponsor_summary':
          await _generateSponsorSummaryReport(locale);
          break;
        case 'sponsor_detailed':
          await _generateSponsorDetailedReport(locale);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.get('report_created_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.get('error_creating_report')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateAllOrphansReport(Locale locale) async {
    final l = AppLocalizations.of(context)!;
    if (_children.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.get('no_orphans_for_report'))));
      return;
    }

    final reportDate = DateTime(_selectedYear, _selectedMonth);
    await SponsorReportPDF.generateAllOrphansReport(
      _children,
      reportDate,
      context: context,
      locale: locale,
      selectedColumns: _selectedColumns,
    );
  }

  Future<void> _generateSingleOrphanReport(Locale locale) async {
    final child = _children.firstWhere((c) => c.id == _selectedPersonId);
    await OrphanReportPDF.generateAndOpen(
      child,
      context: context,
      locale: locale,
      filterMode: _selectedFilterSubMode,
      selectedYear: _selectedYear,
      selectedMonth: _selectedMonth,
      startDate: _startDate,
      endDate: _endDate,
      reportTitleKey: 'report_type_single_orphan',
    );
  }

  Future<void> _generateOrphanForm(Locale locale) async {
    final child = _children.firstWhere((c) => c.id == _selectedPersonId);
    await OrphanReportPDF.generateAndOpen(
      child,
      context: context,
      locale: locale,
      filterMode: 'none',
      reportTitleKey: 'orphan_form_title',
    );
  }

  Future<void> _generateOrphanFinancialReport(Locale locale) async {
    final child = _children.firstWhere((c) => c.id == _selectedPersonId);
    await OrphanReportPDF.generateAndOpen(
      child,
      context: context,
      locale: locale,
      filterMode: _selectedFilterSubMode,
      selectedYear: _selectedYear,
      selectedMonth: _selectedMonth,
      startDate: _startDate,
      endDate: _endDate,
      includePaymentsTable: true,
      reportTitleKey: 'orphan_financial_report',
      onlyFinancial: true,
    );
  }

  /// Helper method to safely match if a child is sponsored by a specific sponsor
  /// Handles null checks and case-insensitive name matching
  bool _isSponsoredByThisSponsor(Child child, Sponsor sponsor) {
    if (child.sponsor == null) return false;

    final childSponsor = child.sponsor!;

    // Match by ID (primary method - most reliable)
    if (childSponsor.id != null &&
        sponsor.id != null &&
        childSponsor.id!.isNotEmpty &&
        sponsor.id!.isNotEmpty) {
      if (childSponsor.id == sponsor.id) return true;
    }

    // Match by name (case-insensitive fallback for reliability)
    if (childSponsor.name.isNotEmpty && sponsor.name.isNotEmpty) {
      if (childSponsor.name.trim().toLowerCase() ==
          sponsor.name.trim().toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  Future<void> _generateSponsorSummaryReport(Locale locale) async {
    final sponsor = _sponsors.firstWhere(
      (s) => s.id == _selectedPersonId || s.name == _selectedPersonId,
    );
    final sponsoredChildren =
        _children.where((c) => _isSponsoredByThisSponsor(c, sponsor)).toList();
    final month = DateTime(_selectedYear, _selectedMonth);

    // تحديد نوع التقرير بناءً على الخيار المختار
    String reportType = 'monthly';
    if (_selectedFilterSubMode == 'yearly') {
      reportType = 'yearly';
    } else if (_selectedFilterSubMode == 'range') {
      reportType = 'range';
    }

    // جلب الدفعات لكل طفل
    final Map<String, List<Payment>> paymentsMap = {};
    for (final child in sponsoredChildren) {
      paymentsMap[child.id] = await _dbService.listPayments(childId: child.id);
    }

    await SponsorReportPDF.generateSponsorshipReport(
      sponsor,
      sponsoredChildren,
      context: context,
      locale: locale,
      reportType: reportType,
      startDate: _startDate,
      endDate: _endDate,
      month: month,
      paymentsMap: paymentsMap,
    );
  }

  Future<void> _generateSponsorDetailedReport(Locale locale) async {
    final sponsor = _sponsors.firstWhere(
      (s) => s.id == _selectedPersonId || s.name == _selectedPersonId,
    );
    final sponsoredChildren =
        _children.where((c) => _isSponsoredByThisSponsor(c, sponsor)).toList();
    final month = DateTime(_selectedYear, _selectedMonth);

    // جلب الدفعات لكل طفل
    final Map<String, List<Payment>> paymentsMap = {};
    for (final child in sponsoredChildren) {
      paymentsMap[child.id] = await _dbService.listPayments(childId: child.id);
    }

    // تحديد نوع التقرير بناءً على الخيار المختار
    String reportType = 'monthly';
    if (_selectedFilterSubMode == 'yearly') {
      reportType = 'yearly';
    } else if (_selectedFilterSubMode == 'range') {
      reportType = 'range';
    }

    await SponsorReportPDF.generateMonthlyReport(
      sponsor,
      sponsoredChildren,
      month,
      context: context,
      locale: locale,
      reportType: reportType,
      startDate: _startDate,
      endDate: _endDate,
      paymentsMap: paymentsMap,
    );
  }

  Future<void> _generateUnsponsoredReport(Locale locale) async {
    final unsponsoredChildren =
        _children.where((c) => c.isUnsponsored).toList();
    final reportDate = DateTime(_selectedYear, _selectedMonth);
    await SponsorReportPDF.generateUnSponsoredChildrenReport(
      unsponsoredChildren,
      reportDate,
      context: context,
      locale: locale,
      selectedColumns: _selectedColumns,
    );
  }

  Future<void> _generateSponsoredOrphansReport(Locale locale) async {
    final sponsoredChildren = _children.where((c) => c.isSponsored).toList();
    final reportDate = DateTime.now();
    await SponsorReportPDF.generateSponsoredOrphansReport(
      sponsoredChildren,
      reportDate,
      context: context,
      locale: locale,
      selectedColumns: _selectedColumns,
    );
  }

  Future<void> _generateUnregisteredUnsponsoredReport(Locale locale) async {
    // This report identifies unregistered siblings (children mentioned only in siblings list)
    // who are not directly registered and have no sponsorship
    final l = AppLocalizations.of(context)!;

    // Collect all unregistered unsponsored siblings
    final unregisteredUnsponsoredSiblings = <Map<String, dynamic>>[];
    final registeredIds = _children.map((c) => c.id).toSet();

    for (var child in _children) {
      for (var sibling in child.siblings) {
        final siblingId = sibling['id'] as String?;
        final siblingName = sibling['name'] as String?;
        final isSponsored = sibling['isSponsored'] as bool? ?? false;
        final siblingBirthDate = sibling['dateOfBirth'] as DateTime?;

        // Only include if: not registered as primary AND not sponsored
        if (siblingId != null &&
            !registeredIds.contains(siblingId) &&
            !isSponsored &&
            siblingName != null) {
          // Avoid duplicates
          if (!unregisteredUnsponsoredSiblings.any(
            (s) => s['id'] == siblingId,
          )) {
            unregisteredUnsponsoredSiblings.add({
              'id': siblingId,
              'name': siblingName,
              'isSponsored': false,
              'parentChild': child.fullName, // Parent registered child name
              'dateOfBirth': siblingBirthDate,
            });
          }
        }
      }
    }

    if (unregisteredUnsponsoredSiblings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.get('no_unsponsored_siblings_found'))),
      );
      return;
    }

    final reportDate = DateTime(_selectedYear, _selectedMonth);
    await SponsorReportPDF.generateUnregisteredUnsponsoredReport(
      unregisteredUnsponsoredSiblings,
      reportDate,
      context: context,
      locale: locale,
    );
  }
}

// Dialog widget for person selection
class _PersonSelectionDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final Widget Function(T) itemBuilder;

  const _PersonSelectionDialog({
    required this.title,
    required this.items,
    required this.itemBuilder,
  });

  @override
  State<_PersonSelectionDialog<T>> createState() =>
      _PersonSelectionDialogState<T>();
}

class _PersonSelectionDialogState<T> extends State<_PersonSelectionDialog<T>> {
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems =
            widget.items.where((item) {
              if (item is Child) {
                return item.fullName.contains(query) || item.id.contains(query);
              } else if (item is Sponsor) {
                return item.name.contains(query) ||
                    item.currency.contains(query) ||
                    (item.id != null && item.id!.contains(query));
              }
              return false;
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: l.get('search_label'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterItems,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(item),
                    child: widget.itemBuilder(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.get('cancel_button')),
        ),
      ],
    );
  }
}
