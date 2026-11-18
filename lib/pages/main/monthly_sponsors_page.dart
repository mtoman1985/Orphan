import 'package:flutter/material.dart';
import '../reports/sponsor_report.dart';
import '../../services/sqlite_service.dart';
import '../../models/sponsor.dart';

class MonthlySponsorsPage extends StatefulWidget {
  const MonthlySponsorsPage({super.key});

  @override
  State<MonthlySponsorsPage> createState() => _MonthlySponsorsPageState();
}

class _MonthlySponsorsPageState extends State<MonthlySponsorsPage> {
  late SqliteService _dbService;

  // Report parameters
  DateTime _selectedMonth = DateTime.now();
  String _selectedSponsor = 'Any';
  String _selectedCenter = 'All Centers';
  String _selectedStatus = 'All';
  String _selectedCurrency = 'USD';
  String _includeEmailSummary = 'Yes';
  String _attachStatements = 'PDF + CSV';

  // Search and stats
  String _type = 'Individual';
  final int _totalSponsors = 58;
  final int _totalChildren = 82;

  // Dummy data for sponsors/children
  final List<Map<String, dynamic>> _sponsorList = [
    {
      'name': 'HopeCare International',
      'type': 'Org',
      'id': 'SP-014',
      'image': null,
      'children': ['Amina K.', 'Sofia M.'],
    },
    {
      'name': 'Grace A.',
      'type': 'Individual',
      'id': 'SP-027',
      'image': null,
      'children': ['Daniel N.'],
    },
    {
      'name': 'BrightFuture Org.',
      'type': 'Org',
      'id': 'SP-031',
      'image': null,
      'children': ['Noah O. (New)'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _dbService = SqliteService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Sponsors')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Report parameters
            SizedBox(
              width: 340,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Parameters',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text('Month'),
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text:
                                '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}',
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedMonth,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _selectedMonth = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Text('Center'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCenter,
                          items: const [
                            DropdownMenuItem(
                              value: 'All Centers',
                              child: Text('All Centers'),
                            ),
                            DropdownMenuItem(
                              value: 'Center 1',
                              child: Text('Center 1'),
                            ),
                            DropdownMenuItem(
                              value: 'Center 2',
                              child: Text('Center 2'),
                            ),
                          ],
                          onChanged:
                              (v) => setState(
                                () => _selectedCenter = v ?? 'All Centers',
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text('Sponsor'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSponsor,
                          items: const [
                            DropdownMenuItem(value: 'Any', child: Text('Any')),
                            DropdownMenuItem(
                              value: 'HopeCare International',
                              child: Text('HopeCare International'),
                            ),
                            DropdownMenuItem(
                              value: 'Grace A.',
                              child: Text('Grace A.'),
                            ),
                            DropdownMenuItem(
                              value: 'BrightFuture Org.',
                              child: Text('BrightFuture Org.'),
                            ),
                          ],
                          onChanged:
                              (v) =>
                                  setState(() => _selectedSponsor = v ?? 'Any'),
                        ),
                        const SizedBox(height: 12),
                        Text('Status'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(
                              value: 'Active',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'Inactive',
                              child: Text('Inactive'),
                            ),
                          ],
                          onChanged:
                              (v) =>
                                  setState(() => _selectedStatus = v ?? 'All'),
                        ),
                        const SizedBox(height: 12),
                        Text('Currency'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCurrency,
                          items: const [
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          ],
                          onChanged:
                              (v) => setState(
                                () => _selectedCurrency = v ?? 'USD',
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text('Delivery'),
                        DropdownButtonFormField<String>(
                          initialValue: _includeEmailSummary,
                          items: const [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No')),
                          ],
                          onChanged:
                              (v) => setState(
                                () => _includeEmailSummary = v ?? 'Yes',
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text('Attach Statements'),
                        DropdownButtonFormField<String>(
                          initialValue: _attachStatements,
                          items: const [
                            DropdownMenuItem(
                              value: 'PDF + CSV',
                              child: Text('PDF + CSV'),
                            ),
                            DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                            DropdownMenuItem(value: 'CSV', child: Text('CSV')),
                          ],
                          onChanged:
                              (v) => setState(
                                () => _attachStatements = v ?? 'PDF + CSV',
                              ),
                        ),
                        const SizedBox(height: 18),

                        // Quick Add Sponsor (sidebar)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quick Add Sponsor',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: TextEditingController(),
                                decoration: const InputDecoration(
                                  labelText: 'Sponsor Name',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) {},
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: TextEditingController(),
                                decoration: const InputDecoration(
                                  labelText: 'Sponsor National ID',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) {},
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedCurrency,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'USD',
                                    child: Text('USD'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'EUR',
                                    child: Text('EUR'),
                                  ),
                                ],
                                onChanged:
                                    (v) => setState(
                                      () => _selectedCurrency = v ?? 'USD',
                                    ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Currency',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // Add sponsor to list (temporary ID)
                                        // NOTE: controllers are ephemeral here; consider promoting to state fields if persistent inputs are required.
                                        final id =
                                            'SP-${DateTime.now().millisecondsSinceEpoch % 100000}';
                                        setState(() {
                                          _sponsorList.add({
                                            'name': 'New Sponsor',
                                            'type': 'Individual',
                                            'id': id,
                                            'image': null,
                                            'children': <String>[],
                                          });
                                        });
                                      },
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Add Sponsor'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        ElevatedButton.icon(
                          onPressed: () => _showReportTypeDialog(context),
                          icon: const Icon(Icons.bar_chart),
                          label: const Text('Generate Report'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.archive),
                          label: const Text('Export All (ZIP)'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.email),
                          label: const Text('Send Emails'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Generation compiles child updates, payments, and sponsorship status for the selected month.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            // Right column: Search, stats, sponsor/child list
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText:
                                  'Search sponsors, months, or child IDs...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _type,
                          items: const [
                            DropdownMenuItem(
                              value: 'Individual',
                              child: Text('Individual'),
                            ),
                            DropdownMenuItem(value: 'Org', child: Text('Org')),
                          ],
                          onChanged:
                              (v) => setState(() => _type = v ?? 'Individual'),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _selectedCenter,
                          items: const [
                            DropdownMenuItem(
                              value: 'All Centers',
                              child: Text('All Centers'),
                            ),
                            DropdownMenuItem(
                              value: 'Center 1',
                              child: Text('Center 1'),
                            ),
                            DropdownMenuItem(
                              value: 'Center 2',
                              child: Text('Center 2'),
                            ),
                          ],
                          onChanged:
                              (v) => setState(
                                () => _selectedCenter = v ?? 'All Centers',
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.teal[50],
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const Text(
                                    'Total Sponsors',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$_totalSponsors',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            color: Colors.blue[50],
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const Text(
                                    'Children Covered',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$_totalChildren',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: const [
                                Expanded(
                                  child: Text(
                                    'Sponsor',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Children',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ..._sponsorList.map(
                            (s) => ListTile(
                              leading: CircleAvatar(child: Text(s['name'][0])),
                              title: Text(s['name']),
                              subtitle: Text('${s['type']} • ID: ${s['id']}'),
                              trailing: SizedBox(
                                width: 180,
                                child: Text(s['children'].join(', ')),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '3 of $_totalSponsors sponsors shown • Use filters to narrow results.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
          ],
        ),
      ),
    );
  }

  void _showReportTypeDialog(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textDir = isArabic ? TextDirection.rtl : TextDirection.ltr;

    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: textDir,
            child: AlertDialog(
              title: const Text('Select Report Type'),
              content: const Text(
                'What type of report would you like to generate?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _generateMonthlyReport(context);
                  },
                  child: const Text('Monthly Report'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _generateSponsorshipReport(context);
                  },
                  child: const Text('Sponsorship Details'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _generateUnSponsoredChildrenReport(context);
                  },
                  child: const Text('Unsponsored Children'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
    );
  }

  void _generateMonthlyReport(BuildContext context) async {
    try {
      // Get all children from database
      final children = await _dbService.listChildren();

      // Extract unique sponsors from children
      final sponsorMap = <String, Sponsor>{};
      for (final child in children) {
        if (child.sponsor != null && child.sponsor!.id != null) {
          sponsorMap[child.sponsor!.id!] = child.sponsor!;
        }
      }

      // Get selected sponsor
      Sponsor? selectedSponssor;
      if (_selectedSponsor != 'Any' && sponsorMap.isNotEmpty) {
        selectedSponssor = sponsorMap.values.firstWhere(
          (s) => s.name == _selectedSponsor,
          orElse: () => sponsorMap.values.first,
        );
      }

      if (selectedSponssor == null && _selectedSponsor != 'Any') {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sponsor not found')));
        return;
      }

      if (selectedSponssor == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sponsors found in database')),
        );
        return;
      }

      // Filter children by sponsor
      final filteredChildren =
          children.where((c) => c.sponsor?.id == selectedSponssor!.id).toList();

      if (filteredChildren.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No children found for this sponsor')),
        );
        return;
      }

      // Generate monthly report
      await SponsorReportPDF.generateMonthlyReport(
        selectedSponssor,
        filteredChildren,
        _selectedMonth,
        context: context,
        locale: Localizations.localeOf(context),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monthly report generated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
    }
  }

  void _generateSponsorshipReport(BuildContext context) async {
    try {
      // Get all children from database
      final children = await _dbService.listChildren();

      // Extract unique sponsors from children
      final sponsorMap = <String, Sponsor>{};
      for (final child in children) {
        if (child.sponsor != null && child.sponsor!.id != null) {
          sponsorMap[child.sponsor!.id!] = child.sponsor!;
        }
      }

      // Get selected sponsor
      Sponsor? selectedSponssor;
      if (_selectedSponsor != 'Any' && sponsorMap.isNotEmpty) {
        selectedSponssor = sponsorMap.values.firstWhere(
          (s) => s.name == _selectedSponsor,
          orElse: () => sponsorMap.values.first,
        );
      }

      if (selectedSponssor == null && _selectedSponsor != 'Any') {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sponsor not found')));
        return;
      }

      if (selectedSponssor == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sponsors found in database')),
        );
        return;
      }

      // Filter children by sponsor
      final filteredChildren =
          children.where((c) => c.sponsor?.id == selectedSponssor!.id).toList();

      // Generate sponsorship report
      await SponsorReportPDF.generateSponsorshipReport(
        selectedSponssor,
        filteredChildren,
        context: context,
        locale: Localizations.localeOf(context),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sponsorship report generated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
    }
  }

  void _generateUnSponsoredChildrenReport(BuildContext context) async {
    try {
      // Get all children from database
      final children = await _dbService.listChildren();

      // Filter unsponsored children
      final unSponsoredChildren =
          children.where((c) => c.isUnsponsored).toList();

      if (unSponsoredChildren.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All children have sponsors!')),
        );
        return;
      }

      // Generate unsponsored children report
      await SponsorReportPDF.generateUnSponsoredChildrenReport(
        unSponsoredChildren,
        DateTime.now(),
        context: context,
        locale: Localizations.localeOf(context),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unsponsored children report generated: ${unSponsoredChildren.length} children',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
    }
  }
}
