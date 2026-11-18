import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:uuid/uuid.dart';
import '../../models/child.dart';
import '../../models/sponsor.dart';
import '../../services/storage_service.dart';
import '../../services/sqlite_service.dart';
import '../../services/child_data_transfer_service.dart';
import '../../services/web_cache_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';
import '../registration/registration_form.dart';
import '../reports/pdf_report.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../widgets/universal_image.dart';

enum _DuplicateAction { replace, skip, cancelRemaining }

class ChildrenPage extends StatefulWidget {
  final VoidCallback? onOpenCreate;
  const ChildrenPage({super.key, this.onOpenCreate});

  @override
  State<ChildrenPage> createState() => _ChildrenPageState();
}

class _ChildrenPageState extends State<ChildrenPage> {
  final List<Child> _children = [];
  String _query = '';
  String? _loadError;
  bool _isLoading = true;
  bool _isBulkUpdating = false;
  String _activeStatFilter = 'all';
  final Set<String> _selectedChildIds = {};

  @override
  void initState() {
    super.initState();
    FirebaseSyncService().syncCompleted.addListener(_refreshAfterSync);
    WebCacheService().revision.addListener(_refreshAfterSync);
    _load();
  }

  void _refreshAfterSync() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    FirebaseSyncService().syncCompleted.removeListener(_refreshAfterSync);
    WebCacheService().revision.removeListener(_refreshAfterSync);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final list = await StorageService().listChildren();
      if (!mounted) return;
      setState(() {
        _children
          ..clear()
          ..addAll(list);
        _selectedChildIds.retainAll(list.map((child) => child.id));
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to load child records: $e\n$stackTrace');
      if (!mounted) return;
      setState(() => _loadError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<PlatformFile?> _pickImportFile() async {
    final l = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: l.import_orphan_data,
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'db', 'sqlite', 'sqlite3'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files.single;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('${l.get('importFailed')}: $e'),
          ),
        );
      }
    }
    return null;
  }

  Future<List<Child>?> _chooseChildrenForExport() async {
    var exportAll = true;
    final selectedIds = <String>{};

    return showDialog<List<Child>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.export_orphan_data),
                  content: SizedBox(
                    width: 420,
                    height: 420,
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                )!.export_all_children,
                              ),
                              selected: exportAll,
                              onSelected:
                                  (_) => setDialogState(() => exportAll = true),
                            ),
                            ChoiceChip(
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                )!.export_selected_children,
                              ),
                              selected: !exportAll,
                              onSelected:
                                  (_) =>
                                      setDialogState(() => exportAll = false),
                            ),
                          ],
                        ),
                        const Divider(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _children.length,
                            itemBuilder: (context, index) {
                              final child = _children[index];
                              return CheckboxListTile(
                                value: selectedIds.contains(child.id),
                                title: Text(child.fullName),
                                subtitle: Text(child.childIdNumber),
                                dense: true,
                                onChanged:
                                    exportAll
                                        ? null
                                        : (selected) {
                                          setDialogState(() {
                                            if (selected == true) {
                                              selectedIds.add(child.id);
                                            } else {
                                              selectedIds.remove(child.id);
                                            }
                                          });
                                        },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.get('cancel')),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (!exportAll && selectedIds.isEmpty) return;
                        Navigator.pop(
                          context,
                          exportAll
                              ? List<Child>.from(_children)
                              : _children
                                  .where(
                                    (child) => selectedIds.contains(child.id),
                                  )
                                  .toList(),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.get('exportDB'),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _exportChildren() async {
    final children = await _chooseChildrenForExport();
    if (children == null || !mounted) return;
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.select_child_first),
        ),
      );
      return;
    }

    try {
      final bytes = ChildDataTransferService.exportChildren(
        children,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      final result = await FilePicker.platform.saveFile(
        dialogTitle: AppLocalizations.of(context)!.export_orphan_data,
        fileName: 'orphans.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );
      if (mounted && (kIsWeb || result != null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.export_orphan_data}: '
              '${children.length} ${AppLocalizations.of(context)!.get('childrenRecords')}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.get('exportFailed')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importChildren() async {
    final file = await _pickImportFile();
    if (file == null || !mounted) return;

    try {
      final extension = file.extension?.toLowerCase();
      final rows =
          extension == 'xlsx'
              ? ChildDataTransferService.importExcel(file.bytes ?? Uint8List(0))
              : await ChildDataTransferService.importDatabase(
                path: file.path,
                bytes: file.bytes,
              );
      final existingChildren =
          kIsWeb
              ? await WebCacheService().getChildren(forceRefresh: true)
              : await StorageService().listChildren();
      var importedCount = 0;
      var skippedCount = 0;

      for (final row in rows) {
        final child = ChildDataTransferService.decodeChild(row);
        if (child.fullName.trim().isEmpty &&
            (child.nationalId == null || child.nationalId!.trim().isEmpty)) {
          skippedCount++;
          continue;
        }

        final nationalId = _normalizeNationalId(child.nationalId);
        Child? existing;
        if (nationalId.isNotEmpty) {
          for (final candidate in existingChildren) {
            if (_normalizeNationalId(candidate.nationalId) == nationalId) {
              existing = candidate;
              break;
            }
          }
        }

        if (existing != null) {
          final action = await _askDuplicateAction(child);
          if (!mounted || action == _DuplicateAction.cancelRemaining) break;
          if (action == _DuplicateAction.skip) {
            skippedCount++;
            continue;
          }
          child
            ..id = existing.id
            ..childIdNumber = existing.childIdNumber;
        } else {
          child
            ..id = const Uuid().v4()
            ..childIdNumber = await _generateUniqueChildCode(
              child,
              existingChildren,
            );
        }

        child.isSynced = false;
        await SqliteService().insertChild(child);
        existingChildren.removeWhere((item) => item.id == child.id);
        existingChildren.add(child);
        importedCount++;
      }

      if (!mounted) return;
      WebCacheService().clearCache();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.import_completed}: '
              '$importedCount • ${AppLocalizations.of(context)!.import_skipped}: $skippedCount',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.get('importFailed')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<_DuplicateAction> _askDuplicateAction(Child child) async {
    final l = AppLocalizations.of(context)!;
    return await showDialog<_DuplicateAction>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text(l.duplicate_child),
                content: Text(
                  '${child.fullName}\n${l.get('national_id')}: ${child.nationalId}',
                ),
                actions: [
                  TextButton(
                    onPressed:
                        () => Navigator.pop(
                          context,
                          _DuplicateAction.cancelRemaining,
                        ),
                    child: Text(l.get('cancel')),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.pop(context, _DuplicateAction.skip),
                    child: Text(l.skip_child),
                  ),
                  FilledButton(
                    onPressed:
                        () => Navigator.pop(context, _DuplicateAction.replace),
                    child: Text(l.replace_child),
                  ),
                ],
              ),
        ) ??
        _DuplicateAction.cancelRemaining;
  }

  String _normalizeNationalId(String? nationalId) {
    return nationalId?.replaceAll(RegExp(r'[\s-]+'), '').toLowerCase() ?? '';
  }

  Future<String> _generateUniqueChildCode(
    Child child,
    List<Child> existingChildren,
  ) async {
    final country = _canonicalCountry(child.country);
    final generated = await SqliteService().getNextCountryBasedChildId(country);
    final match = RegExp(r'^(IHSAN\d{2})(\d+)$').firstMatch(generated);
    if (match == null) return generated;

    final prefix = match.group(1)!;
    var sequence = int.parse(match.group(2)!);
    final usedCodes =
        existingChildren.map((item) => item.childIdNumber).toSet();
    var candidate = generated;
    while (usedCodes.contains(candidate)) {
      sequence++;
      candidate = '$prefix${sequence.toString().padLeft(4, '0')}';
    }
    return candidate;
  }

  String _canonicalCountry(String? country) {
    final value = country?.trim().toLowerCase();
    const countries = {
      'palestine': 'فلسطين',
      'filistin': 'فلسطين',
      'syria': 'سوريا',
      'suriye': 'سوريا',
      'jordan': 'الأردن',
      'ürdün': 'الأردن',
      'lebanon': 'لبنان',
      'lübnan': 'لبنان',
      'egypt': 'مصر',
      'mısır': 'مصر',
      'turkey': 'تركيا',
      'türkiye': 'تركيا',
    };
    return countries[value] ??
        (country?.trim().isNotEmpty == true ? country!.trim() : 'فلسطين');
  }

  void _selectVisibleChildren(List<Child> children) {
    setState(() => _selectedChildIds.addAll(children.map((child) => child.id)));
  }

  void _selectSiblingGroup(Child child) {
    final siblings = _findLinkedSiblingGroup(child);
    setState(() => _selectedChildIds.addAll(siblings.map((item) => item.id)));
  }

  Set<Child> _findLinkedSiblingGroup(Child child) {
    final group = <Child>{child};
    final pending = <Child>[child];

    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final candidate in _children) {
        if (group.contains(candidate)) continue;
        if (_childrenReferenceEachOther(current, candidate)) {
          group.add(candidate);
          pending.add(candidate);
        }
      }
    }

    if (group.length > 1) return group;

    final fatherId = child.fatherIdNumber.trim();
    final motherId = child.motherIdNumber.trim();
    if (fatherId.isEmpty && motherId.isEmpty) return group;

    return _children.where((candidate) {
      if (candidate.fatherIdNumber.trim() == fatherId && fatherId.isNotEmpty) {
        return true;
      }
      return candidate.motherIdNumber.trim() == motherId && motherId.isNotEmpty;
    }).toSet();
  }

  bool _childrenReferenceEachOther(Child first, Child second) {
    bool references(Child source, Child target) {
      return source.siblings.any((sibling) {
        final profileId = sibling['childProfileId']?.toString();
        final childIdNumber = sibling['childIdNumber']?.toString();
        final nationalId = _normalizeNationalId(sibling['id']?.toString());
        return profileId == target.id ||
            childIdNumber == target.childIdNumber ||
            (target.nationalId?.trim().isNotEmpty == true &&
                nationalId == _normalizeNationalId(target.nationalId));
      });
    }

    return references(first, second) || references(second, first);
  }

  Future<void> _bulkEditSelected() async {
    if (_isBulkUpdating) return;
    final selectedChildren =
        _children
            .where((child) => _selectedChildIds.contains(child.id))
            .toList();
    if (selectedChildren.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    List<Sponsor> sponsors;
    try {
      sponsors =
          (await SqliteService().listSponsors())
              .where((sponsor) => sponsor.isOngoing)
              .toList();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.get('error')}: $error')));
      }
      return;
    }
    if (!mounted) return;

    final controllers = <String, TextEditingController>{
      for (final key in const [
        'father_name',
        'father_id',
        'mother_name',
        'mother_id',
        'guardian_name',
        'guardian_address',
        'guardian_phone',
        'country_label',
        'city',
        'street',
      ])
        key: TextEditingController(),
    };

    Map<String, Object?>? values;
    try {
      values = await showDialog<Map<String, Object?>>(
        context: context,
        builder: (dialogContext) {
          var editFamily = false;
          var editGuardian = false;
          var editAddress = false;
          var sponsorAction = 'keep';

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              Widget textField(String key) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: controllers[key],
                  enabled:
                      (const {
                            'father_name',
                            'father_id',
                            'mother_name',
                            'mother_id',
                          }.contains(key)
                          ? editFamily
                          : const {
                            'guardian_name',
                            'guardian_address',
                            'guardian_phone',
                          }.contains(key)
                          ? editGuardian
                          : editAddress),
                  decoration: InputDecoration(
                    labelText: l10n.get(key),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              );

              bool hasChanges() {
                if (sponsorAction != 'keep') return true;
                bool hasValue(List<String> keys) =>
                    keys.any((key) => controllers[key]!.text.trim().isNotEmpty);

                return (editFamily &&
                        hasValue(const [
                          'father_name',
                          'father_id',
                          'mother_name',
                          'mother_id',
                        ])) ||
                    (editGuardian &&
                        hasValue(const [
                          'guardian_name',
                          'guardian_address',
                          'guardian_phone',
                        ])) ||
                    (editAddress &&
                        hasValue(const ['country_label', 'city', 'street']));
              }

              Widget editSection({
                required String title,
                required bool enabled,
                required ValueChanged<bool?> onChanged,
                required List<String> fields,
              }) => Column(
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(title),
                    value: enabled,
                    onChanged:
                        (value) => setDialogState(() => onChanged(value)),
                  ),
                  for (final field in fields) textField(field),
                ],
              );

              return AlertDialog(
                title: Text(l10n.bulk_edit_selected),
                content: SizedBox(
                  width: 460,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 600),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${l10n.selected_count}: ${selectedChildren.length}',
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: sponsorAction,
                            decoration: InputDecoration(
                              labelText: l10n.get('sponsor_label'),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'keep',
                                child: Text(l10n.sponsorship_unchanged),
                              ),
                              DropdownMenuItem(
                                value: 'clear',
                                child: Text(l10n.remove_sponsorship),
                              ),
                              for (final sponsor in sponsors)
                                DropdownMenuItem(
                                  value: sponsor.id,
                                  child: Text(
                                    sponsor.getNameByLanguage(
                                      Localizations.localeOf(
                                        dialogContext,
                                      ).languageCode,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => sponsorAction = value);
                              }
                            },
                          ),
                          editSection(
                            title: l10n.family_info,
                            enabled: editFamily,
                            onChanged: (value) => editFamily = value == true,
                            fields: const [
                              'father_name',
                              'father_id',
                              'mother_name',
                              'mother_id',
                            ],
                          ),
                          editSection(
                            title: l10n.guardian_info,
                            enabled: editGuardian,
                            onChanged: (value) => editGuardian = value == true,
                            fields: const [
                              'guardian_name',
                              'guardian_address',
                              'guardian_phone',
                            ],
                          ),
                          editSection(
                            title: l10n.address_info,
                            enabled: editAddress,
                            onChanged: (value) => editAddress = value == true,
                            fields: const ['country_label', 'city', 'street'],
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.bulk_edit_empty_unchanged),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(l10n.get('cancel')),
                  ),
                  FilledButton(
                    onPressed:
                        hasChanges()
                            ? () {
                              Navigator.pop(dialogContext, {
                                'editFamily': editFamily,
                                'editGuardian': editGuardian,
                                'editAddress': editAddress,
                                'sponsorAction': sponsorAction,
                                for (final entry in controllers.entries)
                                  entry.key: entry.value.text.trim(),
                              });
                            }
                            : null,
                    child: Text(l10n.get('save_data')),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }

    if (values == null || !mounted) return;
    final sponsorAction = values['sponsorAction'] as String;
    Sponsor? sponsor;
    for (final item in sponsors) {
      if (item.id == sponsorAction) {
        sponsor = item;
        break;
      }
    }
    if (sponsorAction != 'keep' &&
        sponsorAction != 'clear' &&
        sponsor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.get('sponsor_not_found'))));
      return;
    }
    setState(() => _isBulkUpdating = true);
    var updatedCount = 0;
    Object? saveError;

    for (final child in selectedChildren) {
      try {
        if (sponsorAction == 'clear') {
          child.sponsor = null;
          child.sponsorLinkedAt = null;
        } else if (sponsor != null) {
          child.sponsor = sponsor;
          child.sponsorLinkedAt = DateTime.now();
          child.sponsorshipStartDate = DateTime.now();
          child.sponsorshipEndDate = null;
          child.sponsorshipEndReason = null;
        }
        if (values['editFamily'] == true) {
          _applyIfNotEmpty(
            values,
            'father_name',
            (value) => child.fatherName = value,
          );
          _applyIfNotEmpty(
            values,
            'father_id',
            (value) => child.fatherIdNumber = value,
          );
          _applyIfNotEmpty(
            values,
            'mother_name',
            (value) => child.motherName = value,
          );
          _applyIfNotEmpty(
            values,
            'mother_id',
            (value) => child.motherIdNumber = value,
          );
        }
        if (values['editGuardian'] == true) {
          _applyIfNotEmpty(
            values,
            'guardian_name',
            (value) => child.guardianName = value,
          );
          _applyIfNotEmpty(
            values,
            'guardian_address',
            (value) => child.guardianAddress = value,
          );
          _applyIfNotEmpty(
            values,
            'guardian_phone',
            (value) => child.guardianPhone = value,
          );
        }
        if (values['editAddress'] == true) {
          _applyIfNotEmpty(
            values,
            'country_label',
            (value) => child.country = value,
          );
          _applyIfNotEmpty(values, 'city', (value) => child.city = value);
          _applyIfNotEmpty(values, 'street', (value) => child.street = value);
        }
        child.updatedAt = DateTime.now();
        await SqliteService().insertChild(child);
        updatedCount++;
      } catch (error) {
        saveError = error;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _isBulkUpdating = false;
      if (saveError == null) {
        _selectedChildIds.clear();
      } else {
        _selectedChildIds.removeAll(
          selectedChildren.take(updatedCount).map((child) => child.id),
        );
      }
    });
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saveError == null
              ? '${l10n.bulk_update_success}: $updatedCount'
              : '${l10n.bulk_update_failed}: $updatedCount/${selectedChildren.length} — $saveError',
        ),
      ),
    );
  }

  void _applyIfNotEmpty(
    Map<String, Object?> values,
    String key,
    void Function(String) apply,
  ) {
    final value = values[key] as String?;
    if (value != null && value.isNotEmpty) apply(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canBulkEdit =
        Provider.of<AuthService>(
          context,
          listen: false,
        ).currentUser?.canEditOrphans ??
        false;

    // Compute Orphan Statistics
    final totalRegistered = _children.length;
    final ongoingCount = _children.where((c) => c.isSponsored).length;
    final endedCount =
        _children
            .where(
              (c) =>
                  c.sponsor != null &&
                  !c.sponsor!.isOngoing &&
                  c.sponsor!.name.trim().isNotEmpty,
            )
            .length;
    final unsponsoredCount = _children.where((c) => c.isUnsponsored).length;
    int candidatesCount = unsponsoredCount;
    for (final c in _children) {
      for (final sib in c.siblings) {
        if (sib['sponsorshipStatus'] == 'candidate') {
          candidatesCount++;
        }
      }
    }

    final filtered =
        _children.where((c) {
          if (_activeStatFilter == 'ongoing' && !c.isSponsored) return false;
          if (_activeStatFilter == 'ended' &&
              !(c.sponsor != null &&
                  !c.sponsor!.isOngoing &&
                  c.sponsor!.name.trim().isNotEmpty))
            return false;
          if (_activeStatFilter == 'unsponsored' && !c.isUnsponsored)
            return false;
          if (_activeStatFilter == 'candidates') {
            final hasCandidateSibling = c.siblings.any(
              (sib) => sib['sponsorshipStatus'] == 'candidate',
            );
            if (!c.isUnsponsored && !hasCandidateSibling) return false;
          }

          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return c.fullName.toLowerCase().contains(q) ||
              c.childIdNumber.toLowerCase().contains(q) ||
              c.id.toLowerCase().contains(q) ||
              (c.sponsor?.name ?? '').toLowerCase().contains(q);
        }).toList();

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Orphan Summary Statistics Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildOrphanStatCard(
                    title: l10n.get('total_registered_orphans'),
                    value: totalRegistered.toString(),
                    icon: Icons.groups_rounded,
                    color: Colors.blue.shade700,
                    filterKey: 'all',
                    index: 0,
                  ),
                  const SizedBox(width: 12),
                  _buildOrphanStatCard(
                    title: l10n.get('active_sponsorships_label'),
                    value: ongoingCount.toString(),
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                    filterKey: 'ongoing',
                    index: 1,
                  ),
                  const SizedBox(width: 12),
                  _buildOrphanStatCard(
                    title: l10n.get('ended_sponsorships_label'),
                    value: endedCount.toString(),
                    icon: Icons.history_rounded,
                    color: Colors.blueGrey.shade600,
                    filterKey: 'ended',
                    index: 2,
                  ),
                  const SizedBox(width: 12),
                  _buildOrphanStatCard(
                    title: l10n.get('not_sponsored'),
                    value: unsponsoredCount.toString(),
                    icon: Icons.person_off_rounded,
                    color: const Color(0xFFF59E0B),
                    filterKey: 'unsponsored',
                    index: 3,
                  ),
                  const SizedBox(width: 12),
                  _buildOrphanStatCard(
                    title: l10n.get('total_candidates_label'),
                    value: candidatesCount.toString(),
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFF8B5CF6),
                    filterKey: 'candidates',
                    index: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search Bar with Animation
            SlideInLeft(
              duration: const Duration(milliseconds: 700),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          ).get('searchHint'),
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                          ),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons with Animation
            SlideInLeft(
              duration: const Duration(milliseconds: 700),
              delay: const Duration(milliseconds: 100),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildModernButton(
                      label: AppLocalizations.of(context)!.export_orphan_data,
                      icon: Icons.upload_file,
                      onPressed: _exportChildren,
                    ),
                    const SizedBox(width: 8),
                    _buildModernButton(
                      label: AppLocalizations.of(context)!.import_orphan_data,
                      icon: Icons.file_download,
                      onPressed: _importChildren,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Children List with Staggered Animation
            Expanded(
              child: FadeInUp(
                duration: const Duration(milliseconds: 700),
                delay: const Duration(milliseconds: 200),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(
                                context,
                              ).get('childrenRecords'),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${filtered.length} ${AppLocalizations.of(context).get('shown')}',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (canBulkEdit)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed:
                                    filtered.isEmpty || _isBulkUpdating
                                        ? null
                                        : () =>
                                            _selectVisibleChildren(filtered),
                                icon: const Icon(Icons.select_all),
                                label: Text(l10n.select_all_shown),
                              ),
                              TextButton(
                                onPressed:
                                    _selectedChildIds.isEmpty || _isBulkUpdating
                                        ? null
                                        : () =>
                                            setState(_selectedChildIds.clear),
                                child: Text(l10n.clear_selection),
                              ),
                              if (_selectedChildIds.isNotEmpty)
                                FilledButton.icon(
                                  onPressed:
                                      _isBulkUpdating
                                          ? null
                                          : _bulkEditSelected,
                                  icon: const Icon(Icons.edit),
                                  label: Text(
                                    '${l10n.bulk_edit_selected} (${_selectedChildIds.length})',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      // List
                      Expanded(
                        child:
                            filtered.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _loadError == null
                                            ? Icons.child_care_outlined
                                            : Icons.cloud_off_outlined,
                                        size: 48,
                                        color:
                                            _loadError == null
                                                ? Colors.grey[300]
                                                : Colors.red[300],
                                      ),
                                      const SizedBox(height: 12),
                                      if (_isLoading)
                                        const CircularProgressIndicator()
                                      else ...[
                                        Text(
                                          _loadError == null
                                              ? AppLocalizations.of(
                                                context,
                                              ).get('noChildrenFound')
                                              : '${AppLocalizations.of(context).get('error')}: $_loadError',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.copyWith(
                                            color:
                                                _loadError == null
                                                    ? Colors.grey[500]
                                                    : Colors.red[700],
                                          ),
                                        ),
                                        if (_loadError != null) ...[
                                          const SizedBox(height: 12),
                                          OutlinedButton.icon(
                                            onPressed: _load,
                                            icon: const Icon(Icons.refresh),
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              ).get('refresh_data'),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                )
                                : AnimationLimiter(
                                  child: ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder:
                                        (_, __) => Divider(
                                          height: 1,
                                          color: Colors.grey[100],
                                        ),
                                    itemBuilder: (context, index) {
                                      return AnimationConfiguration.staggeredList(
                                        position: index,
                                        duration: const Duration(
                                          milliseconds: 375,
                                        ),
                                        child: SlideAnimation(
                                          horizontalOffset: 50.0,
                                          child: FadeInAnimation(
                                            child: _buildChildRow(
                                              context,
                                              filtered[index],
                                              index,
                                              isSelected: _selectedChildIds
                                                  .contains(filtered[index].id),
                                              canSelect:
                                                  canBulkEdit &&
                                                  !_isBulkUpdating,
                                              onSelectedChanged: (selected) {
                                                setState(() {
                                                  if (selected == true) {
                                                    _selectedChildIds.add(
                                                      filtered[index].id,
                                                    );
                                                  } else {
                                                    _selectedChildIds.remove(
                                                      filtered[index].id,
                                                    );
                                                  }
                                                });
                                              },
                                            ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildChildRow(
    BuildContext context,
    Child c,
    int index, {
    required bool isSelected,
    required bool canSelect,
    required ValueChanged<bool?> onSelectedChanged,
  }) {
    final l = AppLocalizations.of(context)!;
    final portrait = c.documents.isNotEmpty ? c.documents.first : null;
    final rowNumber = index + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (canSelect)
            Checkbox(value: isSelected, onChanged: onSelectedChanged),
          // Avatar - larger size
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: UniversalImage(
                  path: portrait?.filePath ?? '',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  isCircle: true,
                  placeholder: CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  errorWidget: CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: -10,
                top: 20,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  height: 24,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$rowNumber',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Child Info - Name larger with ID beside it
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.getFullNameByLanguage(
                          Localizations.localeOf(context).languageCode,
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        c.isSponsored
                            ? '${l.get('sponsor_label')}: ${c.sponsor!.name}'
                            : l.get('unsponsored_label'),
                        style: TextStyle(
                          fontSize: 18,
                          color:
                              c.isSponsored
                                  ? Colors.blue.shade900
                                  : Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ID Column - beside the name
                Expanded(
                  flex: 2,
                  child: Text(
                    'ID: ${c.childIdNumber}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action Buttons
          Wrap(
            spacing: 4,
            children: [
              if (canSelect)
                _buildActionButton(
                  icon: Icons.groups_rounded,
                  tooltip: l.bulk_select_siblings,
                  color: Colors.teal,
                  onPressed: () => _selectSiblingGroup(c),
                ),
              if (Provider.of<AuthService>(
                    context,
                    listen: false,
                  ).currentUser?.canPrintOrphans ??
                  false)
                _buildActionButton(
                  icon: Icons.picture_as_pdf,
                  tooltip: 'PDF Report',
                  color: Colors.red,
                  onPressed: () async {
                    final locale = Localizations.localeOf(context);
                    await OrphanReportPDF.generateAndOpen(
                      c,
                      context: context,
                      locale: locale,
                    );
                  },
                ),
              if (Provider.of<AuthService>(
                    context,
                    listen: false,
                  ).currentUser?.canEditOrphans ??
                  false)
                _buildActionButton(
                  icon: Icons.edit,
                  tooltip: 'Edit',
                  color: Colors.blue,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RegistrationForm(child: c),
                      ),
                    );
                    _load();
                  },
                ),
              if (Provider.of<AuthService>(
                    context,
                    listen: false,
                  ).currentUser?.canDeleteOrphans ??
                  false)
                _buildActionButton(
                  icon: Icons.delete,
                  tooltip: 'Delete',
                  color: Colors.red,
                  onPressed: () async {
                    final isArabic =
                        Localizations.localeOf(context).languageCode == 'ar';
                    final textDir =
                        isArabic ? TextDirection.rtl : TextDirection.ltr;

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => Directionality(
                            textDirection: textDir,
                            child: AlertDialog(
                              title: Text(l.get('delete_child_title')),
                              content: Text(
                                '${l.get('are_you_sure_delete')} ${c.fullName}?',
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: Text(l.get('cancel')),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: Text(
                                    l.get('delete'),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    );

                    if (confirm == true) {
                      // Delete from Firebase FIRST to ensure it's gone from cloud
                      await FirebaseSyncService().deleteChildFromFirebase(c.id);
                      await SqliteService().deleteChild(c.id);

                      // Update UI immediately
                      setState(() {
                        _children.removeWhere((child) => child.id == c.id);
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${c.fullName} ${l.get('child_deleted')}',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildOrphanStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String filterKey,
    required int index,
  }) {
    final isSelected = _activeStatFilter == filterKey;

    return FadeInLeft(
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: index * 80),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _activeStatFilter =
                  _activeStatFilter == filterKey ? 'all' : filterKey;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 155,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    isSelected
                        ? [color.withOpacity(0.22), color.withOpacity(0.12)]
                        : [color.withOpacity(0.12), color.withOpacity(0.04)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.2),
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isSelected
                          ? color.withOpacity(0.18)
                          : color.withOpacity(0.04),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color.withOpacity(0.95),
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected ? color : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
