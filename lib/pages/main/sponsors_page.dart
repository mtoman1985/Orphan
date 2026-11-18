import 'package:flutter/material.dart';
import 'package:orphan/l10n/app_localizations.dart';
import 'package:orphan/l10n/app_localizations_extension.dart';
import 'package:uuid/uuid.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/sponsor.dart';
import '../../models/child.dart';
import '../../widgets/sponsors_pyramid_hierarchy.dart';
import '../../services/sqlite_service.dart';
import '../../services/web_cache_service.dart';
import 'sponsor_detail_page.dart';
import '../../services/firebase_sync_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SponsorsPage extends StatefulWidget {
  final VoidCallback? onOpenCreateSponsor;

  const SponsorsPage({super.key, this.onOpenCreateSponsor});

  @override
  State<SponsorsPage> createState() => _SponsorsPageState();
}

class _SponsorsPageState extends State<SponsorsPage> {
  final List<Map<String, String>> _sponsors = [];
  late SqliteService _dbService;
  bool _isLoading = true;
  int _ongoingCount = 0;
  int _endedCount = 0;
  int _unsponsoredCount = 0;
  int _paymentsCount = 0;

  // Pyramid statistics state
  List<SponsorStatItem> _institutionsStats = [];
  List<SponsorStatItem> _individualsStats = [];
  int _totalSponsoredCount = 0;
  int _totalCandidatesCount = 0;
  int _institutionsSponsoredCount = 0;
  int _institutionsCandidatesCount = 0;
  int _individualsSponsoredCount = 0;
  int _individualsCandidatesCount = 0;
  String _activeFilter =
      'all'; // 'all', 'institution', 'individual', or sponsorId

  @override
  void initState() {
    super.initState();
    _dbService = SqliteService();
    FirebaseSyncService().syncCompleted.addListener(_refreshAfterSync);
    WebCacheService().revision.addListener(_refreshAfterSync);
    _loadData();
  }

  void _refreshAfterSync() {
    if (mounted) _loadData();
  }

  @override
  void dispose() {
    FirebaseSyncService().syncCompleted.removeListener(_refreshAfterSync);
    WebCacheService().revision.removeListener(_refreshAfterSync);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadSponsors();
    await _loadStats();
    setState(() => _isLoading = false);
  }

  /// Load sponsors from database
  Future<void> _loadSponsors() async {
    try {
      final sponsorsData = await _dbService.listSponsors();
      _sponsors.clear();
      for (var sponsor in sponsorsData) {
        _sponsors.add({
          'id': sponsor.id,
          'name': sponsor.name,
          'startDate': sponsor.startDate.toIso8601String().split('T')[0],
          'relationship': '',
          'sponsorCategory': sponsor.sponsorCategory,
          'address': sponsor.address ?? '',
          'phone': sponsor.phone ?? '',
          'email': sponsor.email ?? '',
        });
      }
    } catch (e) {
      debugPrint('Error loading sponsors: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _dbService.getSponsorshipCounts();
      _ongoingCount = stats['ongoing'] ?? 0;
      _endedCount = stats['ended'] ?? 0;
      _unsponsoredCount = stats['unsponsored'] ?? 0;
      _paymentsCount = stats['paymentsCount'] ?? 0;

      final sponsorsList = await _dbService.listSponsors();
      final allChildren = await _dbService.listChildren();

      // Total ongoing sponsored children
      final totalSponsored = allChildren.where((c) => c.isSponsored).length;

      // Total candidates awaiting sponsorship across system
      int totalCandidates = allChildren.where((c) => c.isUnsponsored).length;
      for (final child in allChildren) {
        for (final sib in child.siblings) {
          if (sib['sponsorshipStatus'] == 'candidate') {
            totalCandidates++;
          }
        }
      }

      final List<SponsorStatItem> instList = [];
      final List<SponsorStatItem> indivList = [];

      for (final sponsor in sponsorsList) {
        // Find children linked to this sponsor
        final sponsorChildren =
            allChildren.where((c) {
              final sp = c.sponsor;
              if (sp == null) return false;
              if (sp.id.isNotEmpty && sp.id == sponsor.id) return true;
              if (sp.linkedSponsorId != null &&
                  sp.linkedSponsorId == sponsor.id) {
                return true;
              }
              if (sponsor.id.isNotEmpty && sp.linkedSponsorId == sponsor.id) {
                return true;
              }
              if (sp.name.trim().isNotEmpty &&
                  sp.name.trim().toLowerCase() ==
                      sponsor.name.trim().toLowerCase()) {
                return true;
              }
              return false;
            }).toList();

        final sponsoredForThis =
            sponsorChildren.where((c) => c.isSponsored).length;

        int candidatesForThis =
            sponsorChildren.where((c) => !c.isSponsored).length;
        for (final c in sponsorChildren) {
          for (final sib in c.siblings) {
            if (sib['sponsorshipStatus'] == 'candidate') {
              candidatesForThis++;
            }
          }
        }

        final raw = _sponsors.firstWhere(
          (m) => m['id'] == sponsor.id,
          orElse:
              () => {
                'id': sponsor.id,
                'name': sponsor.name,
                'startDate': sponsor.startDate.toIso8601String().split('T')[0],
                'relationship': '',
                'sponsorCategory': sponsor.sponsorCategory,
                'address': sponsor.address ?? '',
                'phone': sponsor.phone ?? '',
                'email': sponsor.email ?? '',
              },
        );

        final statItem = SponsorStatItem(
          id: sponsor.id,
          name: sponsor.name,
          category: sponsor.sponsorCategory,
          sponsoredCount: sponsoredForThis,
          candidateCount: candidatesForThis,
          rawData: raw,
        );

        if (sponsor.sponsorCategory == 'institution') {
          instList.add(statItem);
        } else {
          indivList.add(statItem);
        }
      }

      // Sort alphabetically by name
      instList.sort((a, b) => a.name.compareTo(b.name));
      indivList.sort((a, b) => a.name.compareTo(b.name));

      _institutionsStats = instList;
      _individualsStats = indivList;

      _totalSponsoredCount = totalSponsored;
      _totalCandidatesCount = totalCandidates;

      _institutionsSponsoredCount = instList.fold(
        0,
        (sum, item) => sum + item.sponsoredCount,
      );
      _institutionsCandidatesCount = instList.fold(
        0,
        (sum, item) => sum + item.candidateCount,
      );

      _individualsSponsoredCount = indivList.fold(
        0,
        (sum, item) => sum + item.sponsoredCount,
      );
      _individualsCandidatesCount = indivList.fold(
        0,
        (sum, item) => sum + item.candidateCount,
      );
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  /// Helper method to get TextDirection based on locale
  TextDirection getTextDirection(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  void _showAddSponsorDialog({String initialCategory = 'individual'}) {
    final l10n = AppLocalizations.of(context);
    final nameCtl = TextEditingController();
    final addressCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final startDateCtl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );

    _showSponsorForm(
      title: l10n.get('add_new_sponsor_dialog'),
      nameCtl: nameCtl,
      addressCtl: addressCtl,
      phoneCtl: phoneCtl,
      emailCtl: emailCtl,
      startDateCtl: startDateCtl,
      initialCategory: initialCategory,
      onSave: (name, date, category) async {
        final sponsorId = const Uuid().v4();
        final currentUser =
            Provider.of<AuthService>(context, listen: false).currentUser;
        final executorName =
            currentUser?.fullName ?? currentUser?.username ?? 'System';

        await _dbService.insertSponsor(
          Sponsor(
            id: sponsorId,
            name: name,
            sponsorCategory: category,
            organizationName: category == 'institution' ? name : null,
            address:
                addressCtl.text.trim().isEmpty ? null : addressCtl.text.trim(),
            phone: phoneCtl.text.trim().isEmpty ? null : phoneCtl.text.trim(),
            email: emailCtl.text.trim().isEmpty ? null : emailCtl.text.trim(),
            amount: 0.0,
            startDate: date,
            isOngoing: true,
            createdBy: executorName,
            updatedBy: executorName,
          ),
        );
      },
    );
  }

  void _showEditSponsorDialog(Map<String, String> sponsorData) {
    final l10n = AppLocalizations.of(context);
    final nameCtl = TextEditingController(text: sponsorData['name']);
    final addressCtl = TextEditingController(text: sponsorData['address']);
    final phoneCtl = TextEditingController(text: sponsorData['phone']);
    final emailCtl = TextEditingController(text: sponsorData['email']);
    final startDateCtl = TextEditingController(text: sponsorData['startDate']);
    final sponsorId = sponsorData['id'] ?? '';

    _showSponsorForm(
      title: l10n.get('sponsor_edit_title'),
      nameCtl: nameCtl,
      addressCtl: addressCtl,
      phoneCtl: phoneCtl,
      emailCtl: emailCtl,
      startDateCtl: startDateCtl,
      initialCategory: sponsorData['sponsorCategory'] ?? 'individual',
      onSave: (name, date, category) async {
        final existing = await _dbService.getSponsorById(sponsorId);
        final currentUser =
            Provider.of<AuthService>(context, listen: false).currentUser;
        final executorName =
            currentUser?.fullName ?? currentUser?.username ?? 'System';

        await _dbService.insertSponsor(
          Sponsor(
            id: sponsorId,
            name: name,
            sponsorCategory: category,
            amount: existing?.amount ?? 0.0,
            startDate: date,
            endDate: existing?.endDate,
            isOngoing: existing?.isOngoing ?? true,
            organizationId: existing?.organizationId,
            organizationName:
                category == 'institution' ? name : existing?.organizationName,
            address:
                addressCtl.text.trim().isEmpty ? null : addressCtl.text.trim(),
            phone: phoneCtl.text.trim().isEmpty ? null : phoneCtl.text.trim(),
            email: emailCtl.text.trim().isEmpty ? null : emailCtl.text.trim(),
            currency: existing?.currency ?? 'ط´ظٹظƒظ„',
            createdAt: existing?.createdAt,
            createdBy: existing?.createdBy ?? executorName,
            updatedBy: executorName,
          ),
        );
      },
    );
  }

  void _showSponsorForm({
    required String title,
    required TextEditingController nameCtl,
    required TextEditingController addressCtl,
    required TextEditingController phoneCtl,
    required TextEditingController emailCtl,
    required TextEditingController startDateCtl,
    required String initialCategory,
    required Future<void> Function(String name, DateTime date, String category)
    onSave,
  }) {
    final l10n = AppLocalizations.of(context);
    var selectedCategory = initialCategory;
    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: getTextDirection(context),
            child: StatefulBuilder(
              builder:
                  (context, setDialogState) => AlertDialog(
                    title: Text(title),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: InputDecoration(
                              labelText: l10n.get('sponsor_entity_type'),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'individual',
                                child: Text(l10n.get('sponsor_individual')),
                              ),
                              DropdownMenuItem(
                                value: 'institution',
                                child: Text(l10n.get('sponsor_institution')),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => selectedCategory = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nameCtl,
                            decoration: InputDecoration(
                              labelText:
                                  selectedCategory == 'institution'
                                      ? l10n.get('sponsor_institution_name')
                                      : l10n.get('sponsor_name'),
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(
                                selectedCategory == 'institution'
                                    ? Icons.business
                                    : Icons.person,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: addressCtl,
                            decoration: InputDecoration(
                              labelText: l10n.get('address'),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: phoneCtl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: l10n.get('phone'),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: emailCtl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: l10n.get('email'),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: startDateCtl,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: l10n.get('sponsor_start_date'),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.calendar_today),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.edit_calendar),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        startDateCtl.text.isNotEmpty
                                            ? DateTime.tryParse(
                                                  startDateCtl.text,
                                                ) ??
                                                DateTime.now()
                                            : DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      startDateCtl.text =
                                          picked.toIso8601String().split(
                                            'T',
                                          )[0];
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.get('cancel')),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameCtl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                  l10n.get('please_enter_sponsor_name'),
                                ),
                              ),
                            );
                            return;
                          }

                          try {
                            final date =
                                startDateCtl.text.isNotEmpty
                                    ? DateTime.parse(startDateCtl.text)
                                    : DateTime.now();

                            await onSave(
                              nameCtl.text.trim(),
                              date,
                              selectedCategory,
                            );

                            // Sync changes
                            await FirebaseSyncService().integrateAllData();

                            await _loadData();

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text(l10n.get('saved_successfully')),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text('ط®ط·ط£: $e'),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(l10n.get('save')),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredSponsors =
        _sponsors.where((sponsor) {
          if (_activeFilter == 'all') return true;
          if (_activeFilter == 'institution') {
            return sponsor['sponsorCategory'] == 'institution';
          }
          if (_activeFilter == 'individual') {
            return sponsor['sponsorCategory'] != 'institution';
          }
          return sponsor['id'] == _activeFilter;
        }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  l10n.get('sidebar_sponsors'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: ElevatedButton.icon(
                  onPressed: _showAddSponsorDialog,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.get('add_sponsor')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pyramid Statistics Section
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: SponsorsPyramidHierarchy(
              totalSponsoredCount: _totalSponsoredCount,
              totalCandidatesCount: _totalCandidatesCount,
              institutionsSponsoredCount: _institutionsSponsoredCount,
              institutionsCandidatesCount: _institutionsCandidatesCount,
              individualsSponsoredCount: _individualsSponsoredCount,
              individualsCandidatesCount: _individualsCandidatesCount,
              institutions: _institutionsStats,
              individuals: _individualsStats,
              activeFilter: _activeFilter,
              onSelectFilter: (filterType, sponsorId) {
                setState(() {
                  _activeFilter = sponsorId ?? filterType;
                });
              },
              onOpenSponsorDetail: (item) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SponsorDetailPage(sponsorId: item.id),
                  ),
                ).then((_) => _loadData());
              },
              onAddInstitution:
                  () => _showAddSponsorDialog(initialCategory: 'institution'),
              onAddIndividual:
                  () => _showAddSponsorDialog(initialCategory: 'individual'),
            ),
          ),
          const SizedBox(height: 28),

          // Sponsors List Header with Filter Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    l10n.get('sponsors_list'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredSponsors.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_activeFilter != 'all') ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            size: 14,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _activeFilter == 'institution'
                                ? l10n.get('filter_institutions')
                                : _activeFilter == 'individual'
                                ? l10n.get('filter_individuals')
                                : l10n.get('filter_by_selected_sponsor'),
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (_activeFilter != 'all')
                TextButton.icon(
                  onPressed: () => setState(() => _activeFilter = 'all'),
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(l10n.get('show_all')),
                ),
            ],
          ),
          const SizedBox(height: 16),

          filteredSponsors.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.get('no_data'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSponsors.length,
                itemBuilder: (context, index) {
                  final sponsor = filteredSponsors[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 300 + (index * 60)),
                    child: _buildSponsorCard(sponsor, index),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    int index,
  ) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: index * 100),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color.withOpacity(0.9),
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build modern sponsor card
  Widget _buildSponsorCard(Map<String, String> sponsor, int index) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final sponsorId = sponsor['id'] ?? '';
            if (sponsorId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SponsorDetailPage(sponsorId: sponsorId),
                ),
              ).then((_) => _loadData());
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sponsor['name'] ?? l10n.get('unknown'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        sponsor['sponsorCategory'] == 'institution'
                            ? l10n.get('sponsor_institution')
                            : l10n.get('sponsor_individual'),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sponsor['startDate'] ?? 'N/A',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      if ((sponsor['address'] ?? '').isNotEmpty)
                        Text('${l10n.get('address')}: ${sponsor['address']}'),
                      if ((sponsor['phone'] ?? '').isNotEmpty)
                        Text('${l10n.get('phone')}: ${sponsor['phone']}'),
                      if ((sponsor['email'] ?? '').isNotEmpty)
                        Text('${l10n.get('email')}: ${sponsor['email']}'),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconActionButton(
                      icon: Icons.edit,
                      color: Colors.blue,
                      onPressed: () => _showEditSponsorDialog(sponsor),
                    ),
                    const SizedBox(width: 8),
                    _buildIconActionButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onPressed: () => _confirmDeleteSponsor(sponsor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _confirmDeleteSponsor(Map<String, String> sponsor) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: getTextDirection(context),
            child: AlertDialog(
              title: Text(l10n.get('confirm')),
              content: Text(
                '${l10n.get('are_you_sure_delete')} "${sponsor['name']}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.get('cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                  ),
                  onPressed: () async {
                    final sponsorId = sponsor['id'] ?? '';
                    // Delete from Firebase FIRST
                    await FirebaseSyncService().deleteSponsorFromFirebase(
                      sponsorId,
                    );
                    await _dbService.deleteSponsor(sponsorId);
                    // Sync changes
                    await FirebaseSyncService().integrateAllData();
                    await _loadData();
                    if (mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    l10n.get('delete'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
