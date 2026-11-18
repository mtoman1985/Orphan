import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/child.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/sqlite_service.dart';
import '../../services/storage_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../services/backup_service.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class CloudSyncPage extends StatefulWidget {
  final CloudSyncService cloudSync;

  const CloudSyncPage({super.key, required this.cloudSync});

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  final SqliteService _db = SqliteService();
  final StorageService _storage = StorageService();

  bool _isConnected = false;
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncStatus = '';
  List<Child> _children = [];
  List<bool> _selectedChildren = [];
  Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadChildren();
  }

  Future<void> _checkConnection() async {
    final connected = await widget.cloudSync.checkConnection();
    if (mounted) {
      setState(() => _isConnected = connected);
    }
  }

  Future<void> _loadChildren() async {
    final children = await _db.listChildren();
    final counts = await _db.getSponsorshipCounts();
    final sponsors = await _db.listSponsors();
    final payments = await _db.listPayments();

    if (mounted) {
      setState(() {
        _children = children;
        _selectedChildren = List.filled(children.length, false);
        _counts = {
          'الأيتام': children.length,
          'الشامل':
              counts['ongoing']! + counts['ended']! + counts['unsponsored']!,
          'المدفوعات': payments.length,
          'الكفلاء': sponsors.length,
        };
      });
    }
  }

  Future<void> _syncSelectedChildren() async {
    final selectedChildren = [
      for (int i = 0; i < _children.length; i++)
        if (_selectedChildren[i]) _children[i],
    ];

    if (selectedChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار يتيم واحد على الأقل')),
      );
      return;
    }

    await _performSync(selectedChildren);
  }

  Future<void> _syncAllData() async {
    if (_children.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للمزامنة')));
      return;
    }

    await _performSync(_children);
  }

  Future<void> _performSync(List<Child> targets) async {
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
      _syncStatus = 'بدء العملية...';
    });

    try {
      int successCount = 0;
      for (int i = 0; i < targets.length; i++) {
        final child = targets[i];
        setState(() {
          _syncStatus = 'جاري مزامنة: ${child.firstName} ${child.lastName}';
          _syncProgress = i / targets.length;
        });

        // 1. مزامنة الصور إلى GitHub (الأولوية القصوى)
        final images = await _getChildImages(child);
        if (images.isNotEmpty) {
          try {
            await widget.cloudSync.uploadMultipleImages(images, child.id);
          } catch (e) {
            debugPrint('خطأ في رفع صور ${child.id}: $e');
          }
        }

        // 2. مزامنة البيانات السحابية
        try {
          await widget.cloudSync.uploadChild(child);
        } catch (e) {
          debugPrint('خطأ في رفع بيانات ${child.id}: $e');
        }

        successCount++;
        setState(() {
          _syncProgress = (i + 1) / targets.length;
        });
      }

      setState(() => _syncStatus = 'تمت المزامنة بنجاح ($successCount)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت مزامنة $successCount سجلات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _syncStatus = 'فشل: $e');
    } finally {
      setState(() => _isSyncing = false);
      _loadChildren();
    }
  }

  Future<Map<String, File>> _getChildImages(Child child) async {
    final images = <String, File>{};
    final baseDir = await _storage.getBaseDir();

    final imagePaths = {
      'child_photo': child.childPhotoPath,
      'mother_id': child.motherIdPhotoPath,
      'guardian_id': child.guardianIdPhotoPath,
      'father_death_cert': child.fatherDeathCertificatePath,
      'mother_death_cert': child.motherDeathCertificatePath,
    };

    // إضافة كافة الوثائق الموجودة في قائمة documents
    for (var doc in child.documents) {
      if (doc.filePath.isNotEmpty) {
        final key = doc.type.toLowerCase().replaceAll(' ', '_');
        // إذا لم يكن المفتاح موجوداً بالفعل، أضفه
        if (!imagePaths.containsKey(key)) {
          imagePaths[key] = doc.filePath;
        }
      }
    }

    for (var entry in imagePaths.entries) {
      final pathValue = entry.value;
      if (pathValue != null && pathValue.isNotEmpty) {
        File file = File(pathValue);

        // 1. If relative, try baseDir/path
        if (!file.isAbsolute) {
          file = File('${baseDir.path}/$pathValue');
        }

        // 2. If not found, try searching by file name in baseDir/files
        if (!await file.exists()) {
          final fileName = path.basename(pathValue);
          final altFile = File('${baseDir.path}/files/$fileName');
          if (await altFile.exists()) {
            file = altFile;
          }
        }

        if (await file.exists()) {
          images[entry.key] = file;
          debugPrint('Sync: Found image for ${entry.key}: ${file.path}');
        } else {
          debugPrint('Sync: Image NOT found for ${entry.key}: $pathValue');
        }
      }
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('مزامنة الخادم والسحابة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: CustomScrollView(
        slivers: [
          // حالة الاتصال
          SliverToBoxAdapter(
            child: _buildStatusCard().animate().fadeIn().slideY(begin: 0.1),
          ),

          // الأوامر السريعة
          SliverToBoxAdapter(
            child: _buildQuickActions().animate().fadeIn(delay: 100.ms),
          ),

          // إحصائيات
          SliverToBoxAdapter(
            child: _buildStatsGrid().animate().fadeIn(delay: 200.ms),
          ),

          // قائمة الأيتام
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Text(
                    'قائمة الأيتام للمزامنة',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        final allSelected = _selectedChildren.every((v) => v);
                        _selectedChildren = List.filled(
                          _children.length,
                          !allSelected,
                        );
                      });
                    },
                    icon: Icon(
                      _selectedChildren.every((v) => v)
                          ? Icons.deselect
                          : Icons.select_all,
                      size: 20,
                    ),
                    label: Text(
                      _selectedChildren.every((v) => v)
                          ? 'إلغاء الكل'
                          : 'تحديد الكل',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final child = _children[index];
              final isSelected = _selectedChildren[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.blue.withOpacity(0.05)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    value: isSelected,
                    onChanged:
                        (v) => setState(() => _selectedChildren[index] = v!),
                    title: Text(
                      '${child.firstName} ${child.lastName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'كود اليتيم: ${child.childIdNumber}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: isSelected ? Colors.white : Colors.blue[400],
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: _children.length),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton:
          _isSyncing
              ? null
              : FloatingActionButton.extended(
                onPressed: _isConnected ? _syncSelectedChildren : null,
                label: const Text('بدء المزامنة الآن'),
                icon: const Icon(Icons.sync),
                backgroundColor: _isConnected ? Colors.blue : Colors.grey,
              ).animate().scale(),
    );
  }

  Widget _buildStatusCard() {
    return GestureDetector(
      onTap: _isConnected && !_isSyncing ? _syncAllData : null,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                _isConnected
                    ? [const Color(0xFF00B09B), const Color(0xFF96C93D)]
                    : [const Color(0xFFF09819), const Color(0xFFEDDE5D)],
          ),
          boxShadow: [
            BoxShadow(
              color: (_isConnected ? Colors.green : Colors.orange).withOpacity(
                0.4,
              ),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isConnected ? 'متصل' : 'بانتظار الاتصال...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSyncing
                            ? _syncStatus
                            : 'اضغط هنا لبدء المزامنة الشاملة والآمنة',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _checkConnection,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            if (_isSyncing) ...[
              const SizedBox(height: 24),
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 12,
                    width:
                        (MediaQuery.of(context).size.width - 80) *
                        (_syncProgress > 0 ? _syncProgress : 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _actionCard(
            'مزامنة Firebase',
            Icons.local_fire_department_rounded,
            Colors.orange,
            () async {
              await FirebaseSyncService().integrateAllData();
            },
          ),
          _actionCard(
            'تنزيل الكل',
            Icons.cloud_download_rounded,
            Colors.blue,
            () async {
              final remoteChildren =
                  await widget.cloudSync.downloadAllChildren();
              for (var child in remoteChildren) {
                await _db.insertChild(child);
              }
              await _loadChildren();
            },
          ),
          _actionCard(
            'نسخة ZIP',
            Icons.folder_zip_rounded,
            Colors.purple,
            () async {
              setState(() => _syncStatus = 'جاري ضغط البيانات والصور...');
              final file = await BackupService.createBackup();
              debugPrint('Backup created at: ${file.path}');
            },
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    String title,
    IconData icon,
    Color color,
    Future Function() action,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (_isSyncing) return;
          setState(() {
            _isSyncing = true;
            _syncStatus = 'جاري تنفيذ: $title';
          });
          try {
            await action();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تنفيذ $title بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('فشل $title: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isSyncing = false);
              _loadChildren();
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_counts.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
        children:
            _counts.entries
                .map((e) => _statItem(e.key, e.value.toString()))
                .toList(),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
