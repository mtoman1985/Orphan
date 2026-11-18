import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:orphan/l10n/app_localizations.dart';
import 'package:orphan/l10n/app_localizations_extension.dart';

class SponsorStatItem {
  final String id;
  final String name;
  final String category; // 'institution' or 'individual'
  final int sponsoredCount;
  final int candidateCount;
  final Map<String, String>? rawData;

  const SponsorStatItem({
    required this.id,
    required this.name,
    required this.category,
    required this.sponsoredCount,
    required this.candidateCount,
    this.rawData,
  });
}

class SponsorsPyramidHierarchy extends StatefulWidget {
  final int totalSponsoredCount;
  final int totalCandidatesCount;
  final int institutionsSponsoredCount;
  final int institutionsCandidatesCount;
  final int individualsSponsoredCount;
  final int individualsCandidatesCount;
  final List<SponsorStatItem> institutions;
  final List<SponsorStatItem> individuals;
  final String activeFilter; // 'all', 'institution', 'individual', or sponsorId
  final Function(String filterType, String? sponsorId)? onSelectFilter;
  final Function(SponsorStatItem item)? onOpenSponsorDetail;
  final VoidCallback? onAddInstitution;
  final VoidCallback? onAddIndividual;

  const SponsorsPyramidHierarchy({
    super.key,
    required this.totalSponsoredCount,
    required this.totalCandidatesCount,
    required this.institutionsSponsoredCount,
    required this.institutionsCandidatesCount,
    required this.individualsSponsoredCount,
    required this.individualsCandidatesCount,
    required this.institutions,
    required this.individuals,
    this.activeFilter = 'all',
    this.onSelectFilter,
    this.onOpenSponsorDetail,
    this.onAddInstitution,
    this.onAddIndividual,
  });

  @override
  State<SponsorsPyramidHierarchy> createState() =>
      _SponsorsPyramidHierarchyState();
}

class _SponsorsPyramidHierarchyState extends State<SponsorsPyramidHierarchy> {
  bool _isExpanded = true;
  bool _isInstitutionsExpanded = true;
  bool _isIndividualsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of Pyramid Card
          _buildCardHeader(l10n),

          if (_isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEF2F6)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 720;
                  return Column(
                    children: [
                      // LEVEL 1: Apex
                      Center(
                        child: _buildApexNode(l10n),
                      ),

                      // Connector: Apex to Level 2
                      if (isWideScreen)
                        _buildApexToCategoriesConnector(constraints.maxWidth)
                      else
                        _buildSimpleVerticalConnector(),

                      // LEVEL 2 & 3: Branches
                      if (isWideScreen)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Institutions Branch
                            Expanded(
                              child: _buildCategoryBranch(
                                l10n: l10n,
                                title: l10n.get('sponsor_institutions'),
                                icon: Icons.apartment_rounded,
                                gradientColors: const [
                                  Color(0xFF0F766E),
                                  Color(0xFF0D9488),
                                ],
                                sponsoredCount:
                                    widget.institutionsSponsoredCount,
                                candidateCount:
                                    widget.institutionsCandidatesCount,
                                items: widget.institutions,
                                isInstitutions: true,
                                isExpanded: _isInstitutionsExpanded,
                                onToggleExpand: () {
                                  setState(() {
                                    _isInstitutionsExpanded =
                                        !_isInstitutionsExpanded;
                                  });
                                },
                                onAdd: widget.onAddInstitution,
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Individuals Branch
                            Expanded(
                              child: _buildCategoryBranch(
                                l10n: l10n,
                                title: l10n.get('sponsor_individuals'),
                                icon: Icons.person_rounded,
                                gradientColors: const [
                                  Color(0xFF5B21B6),
                                  Color(0xFF7C3AED),
                                ],
                                sponsoredCount:
                                    widget.individualsSponsoredCount,
                                candidateCount:
                                    widget.individualsCandidatesCount,
                                items: widget.individuals,
                                isInstitutions: false,
                                isExpanded: _isIndividualsExpanded,
                                onToggleExpand: () {
                                  setState(() {
                                    _isIndividualsExpanded =
                                        !_isIndividualsExpanded;
                                  });
                                },
                                onAdd: widget.onAddIndividual,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        // Responsive stacked branches for small screens
                        _buildCategoryBranch(
                          l10n: l10n,
                          title: l10n.get('sponsor_institutions'),
                          icon: Icons.apartment_rounded,
                          gradientColors: const [
                            Color(0xFF0F766E),
                            Color(0xFF0D9488),
                          ],
                          sponsoredCount: widget.institutionsSponsoredCount,
                          candidateCount: widget.institutionsCandidatesCount,
                          items: widget.institutions,
                          isInstitutions: true,
                          isExpanded: _isInstitutionsExpanded,
                          onToggleExpand: () {
                            setState(() {
                              _isInstitutionsExpanded =
                                  !_isInstitutionsExpanded;
                            });
                          },
                          onAdd: widget.onAddInstitution,
                        ),
                        const SizedBox(height: 24),
                        _buildCategoryBranch(
                          l10n: l10n,
                          title: l10n.get('sponsor_individuals'),
                          icon: Icons.person_rounded,
                          gradientColors: const [
                            Color(0xFF5B21B6),
                            Color(0xFF7C3AED),
                          ],
                          sponsoredCount: widget.individualsSponsoredCount,
                          candidateCount: widget.individualsCandidatesCount,
                          items: widget.individuals,
                          isInstitutions: false,
                          isExpanded: _isIndividualsExpanded,
                          onToggleExpand: () {
                            setState(() {
                              _isIndividualsExpanded =
                                  !_isIndividualsExpanded;
                            });
                          },
                          onAdd: widget.onAddIndividual,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Card Header with title and controls
  Widget _buildCardHeader(AppLocalizations? l10n) {
    final hasFilter = widget.activeFilter != 'all';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_tree_rounded,
                    color: Colors.blue.shade800,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.get('sponsors_pyramid_title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.get('sponsors_pyramid_subtitle'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasFilter)
                InkWell(
                  onTap: () => widget.onSelectFilter?.call('all', null),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt_off_rounded,
                            size: 14, color: Colors.blue.shade800),
                        const SizedBox(width: 4),
                        Text(
                          l10n.get('clear_filter_show_all'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.blue.shade700,
                ),
                tooltip: _isExpanded
                    ? l10n.get('collapse_pyramid')
                    : l10n.get('expand_pyramid'),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// LEVEL 1: Apex Node
  Widget _buildApexNode(AppLocalizations? l10n) {
    final isSelected = widget.activeFilter == 'all';
    final totalSponsors =
        widget.institutions.length + widget.individuals.length;

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onSelectFilter?.call('all', null),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            constraints: const BoxConstraints(minWidth: 320, maxWidth: 440),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.amberAccent : Colors.white24,
                width: isSelected ? 2.5 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.get('sidebar_sponsors'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${l10n.get('total_registered_sponsors')}: $totalSponsors',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Badges for Sponsored & Candidates
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildPillBadge(
                      label: l10n.get('sponsored_count_label'),
                      count: widget.totalSponsoredCount,
                      icon: Icons.check_circle_rounded,
                      bgTint: Colors.green.shade900.withOpacity(0.4),
                      borderTint: Colors.greenAccent.shade400,
                      textColor: Colors.greenAccent.shade100,
                      numberColor: Colors.white,
                    ),
                    _buildPillBadge(
                      label: l10n.get('candidates_count_label'),
                      count: widget.totalCandidatesCount,
                      icon: Icons.hourglass_top_rounded,
                      bgTint: Colors.amber.shade900.withOpacity(0.4),
                      borderTint: Colors.amberAccent.shade400,
                      textColor: Colors.amberAccent.shade100,
                      numberColor: Colors.white,
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

  /// Connector: From Apex to Level 2
  Widget _buildApexToCategoriesConnector(double totalWidth) {
    return SizedBox(
      height: 48,
      width: totalWidth,
      child: CustomPaint(
        painter: _PyramidForkPainter(
          lineColor: Colors.blue.shade200,
          strokeWidth: 2.2,
        ),
      ),
    );
  }

  /// Simple vertical connector for narrow screens
  Widget _buildSimpleVerticalConnector() {
    return Container(
      width: 2.5,
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.blue.shade200,
    );
  }

  /// Level 2 Category Node & Level 3 Children Branch
  Widget _buildCategoryBranch({
    required AppLocalizations? l10n,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required int sponsoredCount,
    required int candidateCount,
    required List<SponsorStatItem> items,
    required bool isInstitutions,
    required bool isExpanded,
    required VoidCallback onToggleExpand,
    VoidCallback? onAdd,
  }) {
    final filterKey = isInstitutions ? 'institution' : 'individual';
    final isSelected = widget.activeFilter == filterKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Level 2 Node Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onSelectFilter?.call(filterKey, null),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? Colors.amberAccent : Colors.white24,
                  width: isSelected ? 2.5 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${items.length} ${isInstitutions ? l10n.get('unit_institution') : l10n.get('unit_individual')}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: onToggleExpand,
                        tooltip: isExpanded
                            ? l10n.get('collapse_list')
                            : l10n.get('expand_list'),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Badges Row
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildPillBadge(
                        label: l10n.get('sponsored_count_label'),
                        count: sponsoredCount,
                        icon: Icons.check_circle_rounded,
                        bgTint: Colors.black.withOpacity(0.2),
                        borderTint: Colors.greenAccent.shade200,
                        textColor: Colors.greenAccent.shade100,
                        numberColor: Colors.white,
                      ),
                      _buildPillBadge(
                        label: l10n.get('candidates_count_label'),
                        count: candidateCount,
                        icon: Icons.hourglass_top_rounded,
                        bgTint: Colors.black.withOpacity(0.2),
                        borderTint: Colors.amberAccent.shade200,
                        textColor: Colors.amberAccent.shade100,
                        numberColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Vertical stem down to children
        if (isExpanded) ...[
          Center(
            child: Container(
              width: 2.2,
              height: 24,
              color: gradientColors.first.withOpacity(0.4),
            ),
          ),

          // Level 3: List of all Institutions or Individuals
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gradientColors.first.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: gradientColors.first.withOpacity(0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (items.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          size: 36,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isInstitutions
                              ? l10n.get('no_institutions_registered')
                              : l10n.get('no_individuals_registered'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        if (onAdd != null) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(
                              isInstitutions
                                  ? l10n.get('add_institution')
                                  : l10n.get('add_individual'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildSponsorNodeButton(
                          l10n: l10n,
                          item: item,
                          accentColor: gradientColors.first,
                          isInstitution: isInstitutions,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Level 3 Leaf Node Button
  Widget _buildSponsorNodeButton({
    required AppLocalizations? l10n,
    required SponsorStatItem item,
    required Color accentColor,
    required bool isInstitution,
  }) {
    final isSelected = widget.activeFilter == item.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (widget.onOpenSponsorDetail != null) {
            widget.onOpenSponsorDetail!(item);
          } else {
            widget.onSelectFilter?.call('sponsor', item.id);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : accentColor.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? accentColor.withOpacity(0.18)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isInstitution
                            ? Icons.business_outlined
                            : Icons.person_outline,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected ? accentColor : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: accentColor.withOpacity(0.8),
                    ),
                    tooltip: l10n.get('view_sponsor_details'),
                    onPressed: () {
                      if (widget.onOpenSponsorDetail != null) {
                        widget.onOpenSponsorDetail!(item);
                      }
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSubBadge(
                      label: l10n.get('sponsored_label'),
                      count: item.sponsoredCount,
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.green.shade700,
                      bgColor: Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSubBadge(
                      label: l10n.get('candidates_label'),
                      count: item.candidateCount,
                      icon: Icons.hourglass_empty_rounded,
                      color: Colors.amber.shade800,
                      bgColor: Colors.amber.shade50,
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

  /// Pill badge for Level 1 & 2
  Widget _buildPillBadge({
    required String label,
    required int count,
    required IconData icon,
    required Color bgTint,
    required Color borderTint,
    required Color textColor,
    required Color numberColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderTint, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: borderTint),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              color: numberColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Small sub badge for Level 3 items
  Widget _buildSubBadge({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the branching line connecting Level 1 (Apex) to Level 2 (2 Branches)
class _PyramidForkPainter extends CustomPainter {
  final Color lineColor;
  final double strokeWidth;

  _PyramidForkPainter({
    required this.lineColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final leftX = size.width * 0.25;
    final rightX = size.width * 0.75;
    final midY = size.height / 2;

    final path = Path();
    path.moveTo(centerX, 0);
    path.lineTo(centerX, midY);

    path.moveTo(leftX, midY);
    path.lineTo(rightX, midY);

    path.moveTo(leftX, midY);
    path.lineTo(leftX, size.height);

    path.moveTo(rightX, midY);
    path.lineTo(rightX, size.height);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, midY), 3.5, dotPaint);
    canvas.drawCircle(Offset(leftX, midY), 3, dotPaint);
    canvas.drawCircle(Offset(rightX, midY), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PyramidForkPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
