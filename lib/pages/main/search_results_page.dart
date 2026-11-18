import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import 'package:orphan/pages/main/sponsor_detail_page.dart';
import '../../services/sqlite_service.dart';
import '../../models/child.dart';
import '../registration/registration_form.dart';

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  final Function(Child)? onOpenChild;

  const SearchResultsPage({
    super.key,
    required this.searchQuery,
    this.onOpenChild,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late Future<List<Map<String, dynamic>>> _searchResults;
  final SqliteService _dbService = SqliteService();

  @override
  void initState() {
    super.initState();
    _searchResults = _dbService.searchPeople(widget.searchQuery);
  }

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  TextDirection get _textDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: _textDirection,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'رجوع',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "نتائج البحث: ${widget.searchQuery}",
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
          ),
          elevation: 0.5,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _searchResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ أثناء التحميل',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              );
            }
            final results = snapshot.data ?? [];
            if (results.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد نتائج',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder:
                      (context, index) => FadeInUp(
                        duration: const Duration(milliseconds: 250),
                        child: _buildResultCard(results[index], index),
                      ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result, int index) {
    final theme = Theme.of(context);
    final type = (result['type'] ?? '').toString();
    final name = (result['name'] ?? '').toString();
    final relationship = (result['relationship'] ?? '').toString();
    final idNumber = (result['id_number'] ?? '').toString();
    final childCode =
        (result['child_code'] ?? result['orphan_code'] ?? '').toString();

    Color typeColor;
    IconData typeIcon;

    switch (type) {
      case 'child':
        typeColor = Colors.green.shade600;
        typeIcon = Icons.child_care;
        break;
      case 'sponsor':
        typeColor = Colors.deepPurple;
        typeIcon = Icons.volunteer_activism;
        break;
      case 'father':
        typeColor = Colors.orange.shade700;
        typeIcon = Icons.male;
        break;
      case 'mother':
        typeColor = Colors.pink.shade400;
        typeIcon = Icons.female;
        break;
      case 'guardian':
        typeColor = Colors.teal.shade600;
        typeIcon = Icons.security;
        break;
      case 'sibling':
        typeColor = Colors.blue.shade600;
        typeIcon = Icons.group;
        break;
      default:
        typeColor = Colors.grey.shade700;
        typeIcon = Icons.person;
    }

    return InkWell(
      onTap: () => _handleResultTap(result, type),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: typeColor.withOpacity(0.15),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isEmpty ? 'غير معروف' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (type.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: typeColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _localizedTypeLabel(type, relationship),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 12,
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (idNumber.isNotEmpty)
                          _buildDetailField(
                            'رقم الهوية',
                            idNumber,
                            Icons.badge,
                          ),
                        if (childCode.isNotEmpty)
                          _buildDetailField(
                            'كود اليتيم',
                            childCode,
                            Icons.qr_code_2,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizedTypeLabel(String type, String relationship) {
    switch (type) {
      case 'child':
        return 'يتيم';
      case 'sponsor':
        return 'كفيل';
      case 'father':
        return relationship.isNotEmpty ? relationship : 'أب';
      case 'mother':
        return relationship.isNotEmpty ? relationship : 'أم';
      case 'guardian':
        return relationship.isNotEmpty ? relationship : 'ولي أمر';
      case 'sibling':
        return relationship.isNotEmpty ? relationship : 'أخ/أخت';
      default:
        return relationship.isNotEmpty ? relationship : 'شخص';
    }
  }

  Widget _buildDetailField(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _handleResultTap(
    Map<String, dynamic> result,
    String resultType,
  ) async {
    try {
      if (resultType == 'sponsor') {
        // فتح صفحة تفاصيل الكفيل
        final sponsorId =
            (result['id'] ??
                    result['sponsor_id'] ??
                    result['data']?['sponsor_id'] ??
                    result['data']?['id'])
                ?.toString();

        if (sponsorId != null && sponsorId.isNotEmpty) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SponsorDetailPage(sponsorId: sponsorId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على معرف الكفيل')),
          );
        }
        return;
      }

      int? childId;
      if (resultType == 'child') {
        childId =
            _asInt(result['id']) ??
            _asInt(result['child_id']) ??
            _asInt(result['childId']) ??
            _asInt(result['data']?['id']) ??
            _asInt(result['data']?['child_id']);
      } else {
        childId =
            _asInt(result['child_id']) ??
            _asInt(result['childId']) ??
            _asInt(result['data']?['id']) ??
            _asInt(result['data']?['child_id']);
      }

      if (childId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد يتيم مرتبط بهذه النتيجة')),
        );
        return;
      }

      // تحويل int إلى String
      final Child? child = await _dbService.getChildById(childId.toString());

      if (child == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على ملف اليتيم')),
        );
        return;
      }

      if (widget.onOpenChild != null) {
        widget.onOpenChild!(child);
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RegistrationForm(child: child)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الفتح')));
    }
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
