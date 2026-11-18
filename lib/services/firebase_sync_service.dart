import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child.dart';
import '../models/sponsor.dart';
import '../models/payment.dart';
import '../models/country.dart';
import '../models/city.dart';
import '../models/organization.dart';
import '../models/user.dart';
import 'package:path/path.dart' as p;
import 'sqlite_service.dart';
import 'settings_service.dart';
import 'github_storage_service.dart';
import '../models/finance/customer.dart';
import '../models/finance/item.dart';
import '../models/finance/invoice.dart';
import '../models/finance/purchase.dart';
import '../models/finance/sale.dart';
import '../models/finance/finance_payment.dart';
import 'package:flutter/material.dart';

class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  final ValueNotifier<bool> syncCompleted = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastSyncError = ValueNotifier<String?>(null);

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final SqliteService _sqlite = SqliteService();
  bool _syncRequestedAgain = false;
  Future<void>? _syncInFlight;
  Timer? _autoSyncTimer;
  Timer? _periodicSyncTimer;

  void scheduleAutomaticSync() {
    if (kIsWeb) return;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(const Duration(seconds: 2), () {
      integrateAllData().catchError((Object error, StackTrace stackTrace) {
        debugPrint('Automatic Firebase sync failed: $error\n$stackTrace');
      });
    });
  }

  void startAutomaticSync() {
    if (kIsWeb || (_periodicSyncTimer?.isActive ?? false)) return;
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      integrateAllData().catchError((Object error, StackTrace stackTrace) {
        debugPrint('Periodic Firebase sync failed: $error\n$stackTrace');
      });
    });
    scheduleAutomaticSync();
  }

  void stopAutomaticSync() {
    _autoSyncTimer?.cancel();
    _periodicSyncTimer?.cancel();
    _autoSyncTimer = null;
    _periodicSyncTimer = null;
  }

  /// المقارنة بين تاريخين لتحديد الأحدث
  bool _isLaterThan(DateTime a, DateTime b) {
    return a.isAfter(b);
  }

  /// مزامنة ودمج كافة البيانات بين قاعدة البيانات المحلية و Firebase
  Future<void> integrateAllData() {
    final activeSync = _syncInFlight;
    if (activeSync != null) {
      _syncRequestedAgain = true;
      return activeSync;
    }

    final sync = _integrateAllData();
    _syncInFlight = sync;
    return sync.whenComplete(() {
      if (!identical(_syncInFlight, sync)) return;
      _syncInFlight = null;
      if (_syncRequestedAgain) {
        _syncRequestedAgain = false;
        scheduleMicrotask(() {
          integrateAllData().catchError((Object error, StackTrace stackTrace) {
            debugPrint('Queued Firebase sync failed: $error\n$stackTrace');
          });
        });
      }
    });
  }

  Future<void> _integrateAllData() async {
    try {
      lastSyncError.value = null;
      print('🚀   بدء عملية التكامل الشاملة مع السحابة ...');

      // On web: Skip SQLite entirely, just load from Firebase
      if (kIsWeb) {
        print(
          'ℹ️  [FirebaseSync] Web mode: Loading data from Firebase only (no SQLite)',
        );

        // Create default admin on Firebase if missing (Web only)
        final existingAdmin = await getUserByUsernameFromFirebase('admin');
        if (existingAdmin == null) {
          await saveUserToFirebase(
            AppUser(
              id: 'admin_1',
              username: 'admin',
              fullName: 'المدير العام',
              password: 'admin',
              role: 'admin',
              permissions: [],
              createdAt: DateTime.now(),
              isActive: true,
            ),
          );
          print('✅ [FirebaseSync] Default admin created in Firebase for Web');
        }

        print('✅ Web startup complete - data will load on demand');
        return;
      }

      // Desktop: Full sync with SQLite
      await _sqlite.init();
      print('✅ [FirebaseSync] SQLite initialized');
      final cloudAuthoritativeReconciliation =
          !await SettingsService.hasCompletedCloudReconciliation();

      // Sync children first so unrelated collection errors cannot leave the
      // desktop child list stale.
      await _integrateChildrenAndRelatedData(
        cloudAuthoritative: cloudAuthoritativeReconciliation,
      );

      // 1. مزامنة الدول
      await _integrateCountries();
      // 2. مزامنة المدن
      await _integrateCities();
      // 3. مزامنة المنظمات
      await _integrateOrganizations();
      // 4. مزامنة الكفلاء
      await _integrateSponsors(
        cloudAuthoritative: cloudAuthoritativeReconciliation,
      );
      await _integrateSharedSettings(
        cloudAuthoritative: cloudAuthoritativeReconciliation,
      );
      // 5. مزامنة المستخدمين
      await _integrateUsers();
      // 6. مزامنة البيانات المالية
      await _integrateFinanceData();
      if (cloudAuthoritativeReconciliation) {
        await SettingsService.setCloudReconciliationComplete();
      }

      print('✅ انتهت عملية التكامل بنجاح');
    } catch (e) {
      lastSyncError.value = e.toString();
      print('❌ خطأ في عملية التكامل: $e');
      rethrow;
    } finally {
      syncCompleted.value = !syncCompleted.value; // Toggle to notify
    }
  }

  Future<void> syncSharedSettingsFromFirebase() async {
    final snapshot =
        await _firestore.collection('app_settings').doc('shared').get();
    if (!snapshot.exists) return;
    final data = snapshot.data();
    if (data == null) return;
    await SettingsService.applySharedSettingsFromCloud(data);
  }

  Future<void> _integrateSharedSettings({
    bool cloudAuthoritative = false,
  }) async {
    final reference = _firestore.collection('app_settings').doc('shared');
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      await reference.set(await SettingsService.getSharedSettingsForCloud());
      return;
    }

    final remote = snapshot.data();
    if (remote == null) {
      throw StateError('The shared settings document is empty.');
    }
    final local = await SettingsService.getSharedSettingsForCloud();
    final localUpdatedAt = DateTime.tryParse(
      local['updated_at']?.toString() ?? '',
    );
    final remoteUpdatedAt = _parseDate(
      remote['updated_at'] ?? remote['updatedAt'],
    );
    if (!cloudAuthoritative &&
        localUpdatedAt != null &&
        localUpdatedAt.isAfter(remoteUpdatedAt)) {
      await reference.set(local);
    } else {
      await SettingsService.applySharedSettingsFromCloud(remote);
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> deleteChildFromFirebase(String id) async {
    await _firestore.collection('children').doc(id).delete();
  }

  Future<void> deletePaymentFromFirebase(
    String childId,
    String paymentId,
  ) async {
    await _firestore
        .collection('children')
        .doc(childId)
        .collection('payments')
        .doc(paymentId)
        .delete();
  }

  Future<void> deleteInvoiceFromFirebase(String id) async {
    await _firestore.collection('invoices').doc(id).delete();
  }

  Future<void> deleteCloudRecord(String collection, String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Future<void> _integrateCountries() async {
    final local = await _sqlite.listCountries();
    final remoteSnap = await _firestore.collection('countries').get();
    final remoteMap = {
      for (var doc in remoteSnap.docs) doc.id: Country.fromJson(doc.data()),
    };

    for (var l in local) {
      final r = remoteMap[l.code];

      if (r == null) {
        // Missing from Firebase
        if (l.isSynced) {
          // Cloud deletion
          print(
            '🗑️ [FirebaseSync] Deleting local country ${l.code} (cloud deletion)',
          );
          await _sqlite.deleteCountry(l.id!);
        } else {
          // New local country
          print('📤 [FirebaseSync] Uploading local country: ${l.code}');
          final syncedL = Country.fromJson({...l.toJson(), 'is_synced': 1});
          await _firestore
              .collection('countries')
              .doc(l.code)
              .set(syncedL.toJson());
          await _sqlite.insertCountry(syncedL);
        }
      } else {
        // Exists in both
        if (_isLaterThan(l.updatedAt, r.updatedAt)) {
          final syncedL = Country.fromJson({...l.toJson(), 'is_synced': 1});
          await _firestore
              .collection('countries')
              .doc(l.code)
              .set(syncedL.toJson());
          await _sqlite.insertCountry(syncedL);
        } else if (_isLaterThan(r.updatedAt, l.updatedAt)) {
          final syncedR = Country.fromJson({...r.toJson(), 'is_synced': 1});
          await _sqlite.insertCountry(syncedR);
        } else {
          if (!l.isSynced) {
            await _sqlite.insertCountry(
              Country.fromJson({...l.toJson(), 'is_synced': 1}),
            );
          }
        }
      }
      remoteMap.remove(l.code);
    }
    // New from Firebase
    for (var r in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading remote country: ${r.code}');
      await _sqlite.insertCountry(
        Country.fromJson({...r.toJson(), 'is_synced': 1}),
      );
    }
  }

  Future<void> _integrateCities() async {
    final local = await _sqlite.listCities();
    final remoteSnap = await _firestore.collection('cities').get();
    final remoteMap = {
      for (var doc in remoteSnap.docs) doc.id: City.fromJson(doc.data()),
    };

    for (var l in local) {
      final r = remoteMap[l.id.toString()];

      if (r == null) {
        // Missing from Firebase
        if (l.isSynced) {
          // Cloud deletion
          print(
            '🗑️ [FirebaseSync] Deleting local city ${l.id} (cloud deletion)',
          );
          await _sqlite.deleteCity(l.id!);
        } else {
          // New local city
          print('📤 [FirebaseSync] Uploading local city: ${l.id}');
          final syncedL = City.fromJson({...l.toJson(), 'is_synced': 1});
          await _firestore
              .collection('cities')
              .doc(syncedL.id.toString())
              .set(syncedL.toJson());
          await _sqlite.insertCity(syncedL);
        }
      } else {
        // Exists in both
        if (_isLaterThan(l.updatedAt, r.updatedAt)) {
          final syncedL = City.fromJson({...l.toJson(), 'is_synced': 1});
          await _firestore
              .collection('cities')
              .doc(syncedL.id.toString())
              .set(syncedL.toJson());
          await _sqlite.insertCity(syncedL);
        } else if (_isLaterThan(r.updatedAt, l.updatedAt)) {
          final syncedR = City.fromJson({...r.toJson(), 'is_synced': 1});
          await _sqlite.insertCity(syncedR);
        } else {
          if (!l.isSynced) {
            await _sqlite.insertCity(
              City.fromJson({...l.toJson(), 'is_synced': 1}),
            );
          }
        }
      }
      remoteMap.remove(l.id.toString());
    }
    // New from Firebase
    for (var r in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading remote city: ${r.id}');
      await _sqlite.insertCity(City.fromJson({...r.toJson(), 'is_synced': 1}));
    }
  }

  Future<void> _integrateOrganizations() async {
    final local = await _sqlite.listSupportingOrganizations();
    final remoteSnap =
        await _firestore.collection('supporting_organizations').get();
    final remoteMap = {
      for (var doc in remoteSnap.docs)
        doc.id: Organization.fromJson(doc.data()),
    };

    for (var l in local) {
      final r = remoteMap[l.id.toString()];

      if (r == null) {
        // Missing from Firebase
        if (l.isSynced) {
          // Cloud deletion
          print(
            '🗑️ [FirebaseSync] Deleting local organization ${l.id} (cloud deletion)',
          );
          await _sqlite.deleteSupportingOrganization(l.id!);
        } else {
          // New local organization
          print('📤 [FirebaseSync] Uploading local organization: ${l.id}');
          final syncedL = Organization.fromJson({
            ...l.toJson(),
            'is_synced': 1,
          });
          await _firestore
              .collection('supporting_organizations')
              .doc(syncedL.id.toString())
              .set(syncedL.toJson());
          await _sqlite.insertSupportingOrganization(syncedL);
        }
      } else {
        // Exists in both
        if (_isLaterThan(l.updatedAt, r.updatedAt)) {
          final syncedL = Organization.fromJson({
            ...l.toJson(),
            'is_synced': 1,
          });
          await _firestore
              .collection('supporting_organizations')
              .doc(syncedL.id.toString())
              .set(syncedL.toJson());
          await _sqlite.insertSupportingOrganization(syncedL);
        } else if (_isLaterThan(r.updatedAt, l.updatedAt)) {
          final syncedR = Organization.fromJson({
            ...r.toJson(),
            'is_synced': 1,
          });
          await _sqlite.insertSupportingOrganization(syncedR);
        } else {
          if (!l.isSynced) {
            await _sqlite.insertSupportingOrganization(
              Organization.fromJson({...l.toJson(), 'is_synced': 1}),
            );
          }
        }
      }
      remoteMap.remove(l.id.toString());
    }
    // New from Firebase
    for (var r in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading remote organization: ${r.id}');
      await _sqlite.insertSupportingOrganization(
        Organization.fromJson({...r.toJson(), 'is_synced': 1}),
      );
    }
  }

  Future<void> _integrateSponsors({bool cloudAuthoritative = false}) async {
    final local = await _sqlite.listSponsors();
    final remoteSnap = await _firestore.collection('sponsors').get();
    final remoteMap = {
      for (var doc in remoteSnap.docs) doc.id: Sponsor.fromJson(doc.data()),
    };

    for (var lSponsor in local) {
      if (lSponsor.id == null) continue;
      final rSponsor = remoteMap[lSponsor.id];

      if (rSponsor == null) {
        // Missing from Firebase
        if (cloudAuthoritative || lSponsor.isSynced) {
          // Previously synced => deleted from Firebase
          print(
            '🗑️ [FirebaseSync] Deleting local sponsor ${lSponsor.id} (cloud deletion)',
          );
          await _sqlite.deleteSponsor(lSponsor.id!);
        } else {
          // New local record => upload
          print(
            '📤 [FirebaseSync] Uploading new local sponsor: ${lSponsor.id}',
          );
          lSponsor.isSynced = true;
          await _firestore
              .collection('sponsors')
              .doc(lSponsor.id)
              .set(lSponsor.toJson());
          await _sqlite.insertSponsor(lSponsor);
        }
      } else {
        if (cloudAuthoritative) {
          rSponsor.isSynced = true;
          await _sqlite.insertSponsor(rSponsor);
        } else if (_isLaterThan(lSponsor.updatedAt, rSponsor.updatedAt)) {
          lSponsor.isSynced = true;
          await _firestore
              .collection('sponsors')
              .doc(lSponsor.id)
              .set(lSponsor.toJson());
          await _sqlite.insertSponsor(lSponsor);
        } else if (_isLaterThan(rSponsor.updatedAt, lSponsor.updatedAt)) {
          rSponsor.isSynced = true;
          await _sqlite.insertSponsor(rSponsor);
        } else {
          if (!lSponsor.isSynced) {
            lSponsor.isSynced = true;
            await _sqlite.insertSponsor(lSponsor);
          }
        }
      }
      remoteMap.remove(lSponsor.id);
    }

    // New from Firebase
    for (var rSponsor in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading new remote sponsor: ${rSponsor.id}');
      rSponsor.isSynced = true;
      await _sqlite.insertSponsor(rSponsor);
    }
  }

  Future<void> _integrateChildrenAndRelatedData({
    bool cloudAuthoritative = false,
  }) async {
    final local = await _sqlite.listChildren();
    final remoteSnap = await _firestore.collection('children').get();
    final remoteMap = <String, Child>{};
    for (final doc in remoteSnap.docs) {
      try {
        remoteMap[doc.id] = Child.fromJson({
          ...Map<String, dynamic>.from(doc.data()),
          'id': doc.id,
        });
      } catch (error) {
        throw FormatException(
          'Unable to read Firebase child ${doc.id}: $error',
        );
      }
    }

    for (var lChild in local) {
      final rChild = remoteMap[lChild.id];

      if (rChild == null) {
        // Missing from Firebase
        if (cloudAuthoritative || lChild.isSynced) {
          // It was previously synced, so it must have been deleted from Firebase
          print(
            '🗑️ [FirebaseSync] Deleting local child ${lChild.id} (cloud deletion)',
          );
          await _sqlite.deleteChild(lChild.id);
        } else {
          // New local record, upload it
          print('📤 [FirebaseSync] Uploading new local child: ${lChild.id}');
          await _syncChildImages(lChild);
          lChild.isSynced = true;
          await _firestore
              .collection('children')
              .doc(lChild.id)
              .set(lChild.toJson());
          await _integratePaymentsForChild(
            lChild.id,
            cloudAuthoritative: cloudAuthoritative,
          );
          await _sqlite.insertChild(lChild); // Update synced flag
        }
      } else {
        if (cloudAuthoritative) {
          await _syncChildImagesFromFirebase(rChild);
          await GitHubStorageService.fixChildPaths(rChild);
          rChild.isSynced = true;
          await _sqlite.insertChild(rChild);
          await _integratePaymentsForChild(
            lChild.id,
            cloudAuthoritative: cloudAuthoritative,
          );
        } else if (_isLaterThan(lChild.updatedAt, rChild.updatedAt)) {
          await _syncChildImages(lChild);
          lChild.isSynced = true;
          await _firestore
              .collection('children')
              .doc(lChild.id)
              .set(lChild.toJson());
          await _integratePaymentsForChild(
            lChild.id,
            cloudAuthoritative: cloudAuthoritative,
          );
          await _sqlite.insertChild(lChild); // Update synced flag
        } else if (_isLaterThan(rChild.updatedAt, lChild.updatedAt)) {
          await _syncChildImagesFromFirebase(rChild);
          await GitHubStorageService.fixChildPaths(rChild);
          rChild.isSynced = true;
          await _sqlite.insertChild(rChild);
          await _integratePaymentsForChild(
            lChild.id,
            cloudAuthoritative: cloudAuthoritative,
          );
        } else {
          // Exactly same, just ensure local synced flag is on
          if (!lChild.isSynced) {
            lChild.isSynced = true;
            await _sqlite.insertChild(lChild);
          }
        }
      }
      remoteMap.remove(lChild.id);
    }

    // New from Firebase
    for (var rChild in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading new remote child: ${rChild.id}');
      await _syncChildImagesFromFirebase(rChild);
      await GitHubStorageService.fixChildPaths(rChild);
      rChild.isSynced = true;
      await _sqlite.insertChild(rChild);
      await _integratePaymentsForChild(
        rChild.id,
        cloudAuthoritative: cloudAuthoritative,
      );
    }

    final localChildren = await _sqlite.listChildren();
    final currentRemoteChildren = await _firestore.collection('children').get();
    final localIds = localChildren.map((child) => child.id).toSet();
    final remoteIds = currentRemoteChildren.docs.map((doc) => doc.id).toSet();
    if (!localIds.containsAll(remoteIds) || !remoteIds.containsAll(localIds)) {
      final missingLocally = remoteIds.difference(localIds).take(5).join(', ');
      final missingRemotely = localIds.difference(remoteIds).take(5).join(', ');
      throw StateError(
        'Child sync incomplete: local has ${localChildren.length} readable '
        'records, Firebase has ${currentRemoteChildren.docs.length}; '
        'missing locally: [$missingLocally], missing in Firebase: '
        '[$missingRemotely].',
      );
    }

    debugPrint(
      '✅ [FirebaseSync] Child counts match: '
      '${localChildren.length} local and Firebase records',
    );
  }

  Future<void> _syncChildImages(Child child) async {
    if (kIsWeb) return;
    final dataPath = await SettingsService.getEffectiveDataPath();
    final baseDir = Directory(dataPath);

    for (var doc in child.documents) {
      await _uploadIfExist(
        doc.filePath,
        'children/${child.childIdNumber}/${doc.fileName}',
        baseDir,
      );
    }

    final specificPaths = [
      child.childPhotoPath,
      child.motherIdPhotoPath,
      child.guardianIdPhotoPath,
      child.fatherDeathCertificatePath,
      child.motherDeathCertificatePath,
    ];

    for (var pathValue in specificPaths) {
      if (pathValue != null && pathValue.isNotEmpty) {
        final fileName = p.basename(pathValue);
        await _uploadIfExist(
          pathValue,
          'children/${child.childIdNumber}/$fileName',
          baseDir,
        );
      }
    }
  }

  Future<void> _uploadIfExist(
    String path,
    String remotePath,
    Directory baseDir,
  ) async {
    if (path.isEmpty) return;
    File file = File(path);
    if (!file.isAbsolute) {
      file = File('${baseDir.path}/$path');
    }
    if (!file.existsSync()) {
      final fileName = p.basename(path);
      final altFile = File('${baseDir.path}/files/$fileName');
      if (altFile.existsSync()) file = altFile;
    }
    if (file.existsSync()) {
      print('📤 جاري رفع: $remotePath');
      await uploadFile(file, remotePath);
    }
  }

  Future<void> _syncChildImagesFromFirebase(Child child) async {
    if (kIsWeb) return;
    final dataPath = await SettingsService.getEffectiveDataPath();
    final filesDir = Directory('$dataPath/files');
    if (!await filesDir.exists()) await filesDir.create(recursive: true);

    for (var doc in child.documents) {
      await _downloadIfMissing(
        filesDir,
        sourcePath: doc.filePath,
        fileName: doc.fileName,
        fallbackRemotePath: 'children/${child.childIdNumber}/${doc.fileName}',
      );
    }

    final specificPhotos = {
      if (child.childPhotoPath != null)
        child.childPhotoPath!: child.childPhotoFileName ?? 'profile.jpg',
      if (child.motherIdPhotoPath != null)
        child.motherIdPhotoPath!:
            child.motherIdPhotoFileName ?? 'mother_id.jpg',
      if (child.guardianIdPhotoPath != null)
        child.guardianIdPhotoPath!:
            child.guardianIdPhotoFileName ?? 'guardian_id.jpg',
      if (child.fatherDeathCertificatePath != null)
        child.fatherDeathCertificatePath!:
            child.fatherDeathCertificateFileName ?? 'father_death.jpg',
      if (child.motherDeathCertificatePath != null)
        child.motherDeathCertificatePath!:
            child.motherDeathCertificateFileName ?? 'mother_death.jpg',
    };

    for (var entry in specificPhotos.entries) {
      await _downloadIfMissing(
        filesDir,
        sourcePath: entry.key,
        fileName: entry.value,
        fallbackRemotePath: 'children/${child.childIdNumber}/${entry.value}',
      );
    }
  }

  Future<void> _downloadIfMissing(
    Directory filesDir, {
    required String sourcePath,
    required String fileName,
    required String fallbackRemotePath,
  }) async {
    if (fileName.isEmpty) return;
    final destination = File(p.join(filesDir.path, p.basename(fileName)));
    if (await destination.exists()) return;

    final sourceUri = Uri.tryParse(sourcePath);
    final candidateUrls =
        <String>[
          if (sourceUri != null &&
              (sourceUri.scheme == 'http' || sourceUri.scheme == 'https'))
            sourcePath,
          GitHubStorageService.getImageUrl(fallbackRemotePath),
        ].toSet();

    for (final imageUrl in candidateUrls) {
      final bytes = await GitHubStorageService.downloadImage(imageUrl);
      if (bytes == null) continue;
      await destination.writeAsBytes(bytes);
      return;
    }
  }

  Future<void> _integratePaymentsForChild(
    String childId, {
    bool cloudAuthoritative = false,
  }) async {
    final local = await _sqlite.listPayments(childId: childId);
    final remoteSnap =
        await _firestore
            .collection('children')
            .doc(childId)
            .collection('payments')
            .get();

    final remoteMap = {
      for (var doc in remoteSnap.docs) doc.id: Payment.fromJson(doc.data()),
    };

    for (var lPay in local) {
      final rPay = remoteMap[lPay.id];

      if (rPay == null) {
        // Missing from Firebase
        if (cloudAuthoritative || lPay.isSynced) {
          // It was synced => deleted from Firebase
          print(
            '🗑️ [FirebaseSync] Deleting local payment ${lPay.id} (cloud deletion)',
          );
          await _sqlite.deletePayment(lPay.id);
        } else {
          // New local payment => upload
          print('📤 [FirebaseSync] Uploading local payment: ${lPay.id}');
          lPay.isSynced = true;
          await _firestore
              .collection('children')
              .doc(childId)
              .collection('payments')
              .doc(lPay.id)
              .set(lPay.toJson());
          await _sqlite.insertPayment(lPay); // Update synced flag
        }
      } else if (cloudAuthoritative) {
        rPay.isSynced = true;
        await _sqlite.insertPayment(rPay);
      } else {
        // Exists in both => compare timestamps
        if (_isLaterThan(lPay.updatedAt, rPay.updatedAt)) {
          lPay.isSynced = true;
          await _firestore
              .collection('children')
              .doc(childId)
              .collection('payments')
              .doc(lPay.id)
              .set(lPay.toJson());
          await _sqlite.insertPayment(lPay);
        } else if (_isLaterThan(rPay.updatedAt, lPay.updatedAt)) {
          rPay.isSynced = true;
          await _sqlite.insertPayment(rPay);
        } else {
          if (!lPay.isSynced) {
            lPay.isSynced = true;
            await _sqlite.insertPayment(lPay);
          }
        }
      }
      remoteMap.remove(lPay.id);
    }

    // New from Firebase
    for (var rPay in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading remote payment: ${rPay.id}');
      rPay.isSynced = true;
      await _sqlite.insertPayment(rPay);
    }
  }

  Future<String?> uploadFile(File file, String path) async {
    if (kIsWeb) return null;
    try {
      final bytes = await file.readAsBytes();
      final fileName = p.basename(path);
      final folder = p.dirname(path).replaceAll('\\', '/');
      return await GitHubStorageService.uploadImage(
        bytes: bytes,
        fileName: fileName,
        folder: folder,
      );
    } catch (e) {
      print('❌ خطأ في رفع الملف $path: $e');
      return null;
    }
  }

  // --- PUBLIC API ---

  Future<List<Country>> getAllCountriesFromFirebase() async {
    final snap = await _firestore.collection('countries').get();
    return snap.docs.map((d) => Country.fromJson(d.data())).toList();
  }

  Future<List<City>> getCitiesByCountryFromFirebase(int countryId) async {
    final snap =
        await _firestore
            .collection('cities')
            .where('country_id', isEqualTo: countryId)
            .get();
    return snap.docs.map((d) => City.fromJson(d.data())).toList();
  }

  Future<List<City>> getAllCitiesFromFirebase() async {
    final snap = await _firestore.collection('cities').get();
    return snap.docs.map((d) => City.fromJson(d.data())).toList();
  }

  Future<List<Map<String, dynamic>>> getAllOrganizationsFromFirebase() async {
    final snap = await _firestore.collection('supporting_organizations').get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<Sponsor>> getAllSponsorsFromFirebase() async {
    final snap = await _firestore.collection('sponsors').get();
    return snap.docs.map((d) => Sponsor.fromJson(d.data())).toList();
  }

  Future<void> saveSponsorToFirebase(Sponsor sponsor) async {
    final id = sponsor.id ?? _firestore.collection('sponsors').doc().id;
    sponsor.id = id;
    await _firestore.collection('sponsors').doc(id).set(sponsor.toJson());
  }

  Future<void> deleteSponsorFromFirebase(String id) async {
    await _firestore.collection('sponsors').doc(id).delete();
  }

  Future<Child?> getChildFromFirebase(String id) async {
    final doc = await _firestore.collection('children').doc(id).get();
    if (!doc.exists) return null;
    final child = Child.fromJson({...doc.data()!, 'id': doc.id});
    GitHubStorageService.fixChildPaths(child);
    return child;
  }

  Future<void> saveChildToFirebase(Child child) async {
    await _firestore.collection('children').doc(child.id).set(child.toJson());
  }

  Future<void> syncChildData(Child child) async {
    child.isSynced = true;
    await saveChildToFirebase(child);
    if (!kIsWeb) await _syncChildImages(child);
    await _integratePaymentsForChild(child.id);
    // Locally update synced flag if possible
    if (!kIsWeb) await _sqlite.insertChild(child);
  }

  Future<List<Payment>> getPaymentsFromFirebase(String childId) async {
    final snap =
        await _firestore
            .collection('children')
            .doc(childId)
            .collection('payments')
            .get();
    return snap.docs.map((d) => Payment.fromJson(d.data())).toList();
  }

  Future<void> savePaymentToFirebase(String childId, Payment p) async {
    p.isSynced = true; // Mark as synced
    await _firestore
        .collection('children')
        .doc(childId)
        .collection('payments')
        .doc(p.id)
        .set(p.toJson());
    // Locally update synced flag if possible
    if (!kIsWeb) await _sqlite.insertPayment(p);
  }

  Future<List<Child>> getAllChildrenFromFirebase() async {
    final snap = await _firestore.collection('children').get();
    return snap.docs.map((doc) {
      final c = Child.fromJson({...doc.data(), 'id': doc.id});
      GitHubStorageService.fixChildPaths(c);
      return c;
    }).toList();
  }

  Future<String> getNextCountryBasedChildId(
    String countryName, {
    String? knownCode,
  }) async {
    try {
      final snap =
          await _firestore
              .collection('children')
              .where('country', isEqualTo: countryName)
              .count()
              .get();

      final count = snap.count ?? 0;

      // Use known code if provided, otherwise '99'
      String code = knownCode ?? '99';
      if (code.length < 2) {
        code = code.padLeft(2, '0');
      }

      return 'IHSAN$code${(count + 1).toString().padLeft(4, '0')}';
    } catch (e) {
      print('❌ Error generating ID from Firebase: $e');
      // Fallback
      String code = knownCode ?? '99';
      if (code.length < 2) {
        code = code.padLeft(2, '0');
      }
      // If we can't count, maybe use a timestamp component or random to avoid collision,
      // but for now, let's stick to the requested format and hope for the best or returned 0 count.
      return 'IHSAN$code${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
    }
  }

  // --- USERS ---

  Future<void> _integrateUsers() async {
    try {
      final local = await _sqlite.listUsers();
      final remoteSnap = await _firestore.collection('users').get();
      final remoteMap = {
        for (var doc in remoteSnap.docs) doc.id: AppUser.fromJson(doc.data()),
      };

      for (var l in local) {
        final r = remoteMap[l.id];

        if (r == null) {
          // Missing from Firebase
          if (l.isSynced) {
            // Cloud deletion
            print(
              '🗑️ [FirebaseSync] Deleting local user ${l.id} (cloud deletion)',
            );
            await _sqlite.deleteUser(l.id);
          } else {
            // New local user
            print('📤 [FirebaseSync] Uploading local user: ${l.id}');
            final syncedL = l.copyWith(isSynced: true);
            await _firestore
                .collection('users')
                .doc(syncedL.id)
                .set(syncedL.toJson());
            await _sqlite.insertUser(syncedL);
          }
        } else {
          // Exists in both
          if (_isLaterThan(l.updatedAt, r.updatedAt)) {
            final syncedL = l.copyWith(isSynced: true);
            await _firestore
                .collection('users')
                .doc(syncedL.id)
                .set(syncedL.toJson());
            await _sqlite.insertUser(syncedL);
          } else if (_isLaterThan(r.updatedAt, l.updatedAt)) {
            final syncedR = r.copyWith(isSynced: true);
            await _sqlite.insertUser(syncedR);
          } else {
            if (!l.isSynced) {
              await _sqlite.insertUser(l.copyWith(isSynced: true));
            }
          }
        }
        remoteMap.remove(l.id);
      }
      // New from Firebase
      for (var r in remoteMap.values) {
        print('📥 [FirebaseSync] Downloading remote user: ${r.id}');
        await _sqlite.insertUser(r.copyWith(isSynced: true));
      }
    } catch (e) {
      print('❌ [FirebaseSync] Error integrating users: $e');
    }
  }

  Future<AppUser?> getUserByUsernameFromFirebase(String username) async {
    final snap =
        await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
    if (snap.docs.isEmpty) return null;
    return AppUser.fromJson(snap.docs.first.data());
  }

  Future<List<AppUser>> getAllUsersFromFirebase() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs.map((d) => AppUser.fromJson(d.data())).toList();
  }

  Future<void> saveUserToFirebase(AppUser user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> deleteUserFromFirebase(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> _integrateFinanceData() async {
    print('💰 بدء مزامنة البيانات المالية...');
    await _integrateCustomers();
    await _integrateItems();
    await _integrateInvoices();
    await _integratePurchases();
    await _integrateSales();
    await _integrateFinancePayments();
  }

  Future<void> _integrateCustomers() async {
    final local = await _sqlite.listCustomers();
    final remoteSnap = await _firestore.collection('customers').get();
    final remoteMap = {
      for (var doc in remoteSnap.docs)
        doc.id: Customer.fromJson({
          ...doc.data(),
          'customer_id': int.tryParse(doc.id),
        }),
    };

    for (var l in local) {
      if (l.customerId == null) continue;
      final r = remoteMap[l.customerId.toString()];

      if (r == null) {
        // Missing from Firebase
        if (l.isSynced) {
          // Cloud deletion
          print(
            '🗑️ [FirebaseSync] Deleting local customer ${l.customerId} (cloud deletion)',
          );
          await _sqlite.deleteCustomer(l.customerId!);
        } else {
          // New local customer
          print('📤 [FirebaseSync] Uploading local customer: ${l.customerId}');
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('customers')
              .doc(syncedL.customerId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertCustomer(syncedL);
        }
      } else {
        // Exists in both
        if (_isLaterThan(l.updatedAt, r.updatedAt)) {
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('customers')
              .doc(syncedL.customerId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertCustomer(syncedL);
        } else if (_isLaterThan(r.updatedAt, l.updatedAt)) {
          final syncedR = r.copyWith(isSynced: true);
          await _sqlite.insertCustomer(syncedR);
        } else {
          if (!l.isSynced) {
            await _sqlite.insertCustomer(l.copyWith(isSynced: true));
          }
        }
      }
      remoteMap.remove(l.customerId.toString());
    }
    // New from Firebase
    for (var r in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading remote customer: ${r.customerId}');
      await _sqlite.insertCustomer(r.copyWith(isSynced: true));
    }
  }

  Future<void> _integrateItems() async {
    final local = await _sqlite.listItems();
    final remoteSnap = await _firestore.collection('items').get();
    final remoteMap = {
      for (var doc in remoteSnap.docs)
        doc.id: Item.fromJson({...doc.data(), 'item_id': int.tryParse(doc.id)}),
    };

    for (var l in local) {
      if (l.itemId == null) continue;
      final r = remoteMap[l.itemId.toString()];

      if (r == null) {
        // Missing from Firebase
        if (l.isSynced) {
          // Cloud deletion
          print(
            '🗑️ [FirebaseSync] Deleting local item ${l.itemId} (cloud deletion)',
          );
          await _sqlite.deleteItem(l.itemId!);
        } else {
          // New local item
          print('📤 [FirebaseSync] Uploading local item: ${l.itemId}');
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('items')
              .doc(syncedL.itemId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertItem(syncedL);
        }
      } else {
        // Exists in both
        if (_isLaterThan(l.updatedAt, r.updatedAt)) {
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('items')
              .doc(syncedL.itemId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertItem(syncedL);
        } else if (_isLaterThan(r.updatedAt, l.updatedAt)) {
          final syncedR = r.copyWith(isSynced: true);
          await _sqlite.insertItem(syncedR);
        } else {
          if (!l.isSynced) {
            await _sqlite.insertItem(l.copyWith(isSynced: true));
          }
        }
      }
      remoteMap.remove(l.itemId.toString());
    }
    // New from Firebase
    for (var r in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading remote item: ${r.itemId}');
      await _sqlite.insertItem(r.copyWith(isSynced: true));
    }
  }

  Future<void> _integrateInvoices() async {
    final local = await _sqlite.listInvoices();
    final remoteSnap = await _firestore.collection('invoices').get();
    final remoteMap = {
      for (var doc in remoteSnap.docs)
        doc.id: Invoice.fromJson({
          ...doc.data(),
          'invoice_id': int.tryParse(doc.id),
        }),
    };

    for (var l in local) {
      if (l.invoiceId == null) continue;
      final r = remoteMap[l.invoiceId.toString()];

      if (r == null) {
        // Missing from Firebase
        if (l.isSynced) {
          // Cloud deletion
          print(
            '🗑️ [FirebaseSync] Deleting local invoice ${l.invoiceId} (cloud deletion)',
          );
          await _sqlite.deleteInvoice(l.invoiceId!);
        } else {
          // New local invoice
          print('📤 [FirebaseSync] Uploading local invoice: ${l.invoiceId}');
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('invoices')
              .doc(syncedL.invoiceId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertInvoice(syncedL);
        }
      } else {
        // Exists in both
        if (_isLaterThan(l.updatedAt, r.updatedAt)) {
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('invoices')
              .doc(syncedL.invoiceId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertInvoice(syncedL);
        } else if (_isLaterThan(r.updatedAt, l.updatedAt)) {
          final syncedR = r.copyWith(isSynced: true);
          await _sqlite.insertInvoice(syncedR);
        } else {
          if (!l.isSynced) {
            await _sqlite.insertInvoice(l.copyWith(isSynced: true));
          }
        }
      }
      remoteMap.remove(l.invoiceId.toString());
    }
    // New from Firebase
    for (var r in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading remote invoice: ${r.invoiceId}');
      await _sqlite.insertInvoice(r.copyWith(isSynced: true));
    }
  }

  Future<void> _integratePurchases() async {
    final local = await _sqlite.listAllPurchases();
    final remoteSnap = await _firestore.collection('purchases').get();
    final remoteMap = {
      for (var doc in remoteSnap.docs)
        doc.id: Purchase.fromJson({
          ...doc.data(),
          'purchase_id': int.tryParse(doc.id),
        }),
    };

    for (var l in local) {
      if (l.purchaseId == null) continue;
      final r = remoteMap[l.purchaseId.toString()];

      if (r == null) {
        // Missing from Firebase
        if (l.isSynced) {
          // Cloud deletion
          print(
            '🗑️ [FirebaseSync] Deleting local purchase ${l.purchaseId} (cloud deletion)',
          );
          await _sqlite.deletePurchase(l.purchaseId!);
        } else {
          // New local purchase
          print('📤 [FirebaseSync] Uploading local purchase: ${l.purchaseId}');
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('purchases')
              .doc(syncedL.purchaseId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertPurchase(syncedL);
        }
      } else {
        // Exists in both
        if (_isLaterThan(l.updatedAt, r.updatedAt)) {
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('purchases')
              .doc(syncedL.purchaseId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertPurchase(syncedL);
        } else if (_isLaterThan(r.updatedAt, l.updatedAt)) {
          final syncedR = r.copyWith(isSynced: true);
          await _sqlite.insertPurchase(syncedR);
        } else {
          if (!l.isSynced) {
            await _sqlite.insertPurchase(l.copyWith(isSynced: true));
          }
        }
      }
      remoteMap.remove(l.purchaseId.toString());
    }
    // New from Firebase
    for (var r in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading remote purchase: ${r.purchaseId}');
      await _sqlite.insertPurchase(r.copyWith(isSynced: true));
    }
  }

  Future<void> _integrateSales() async {
    final local = await _sqlite.listAllSales();
    final remoteSnap = await _firestore.collection('sales').get();
    final remoteMap = {
      for (var doc in remoteSnap.docs)
        doc.id: Sale.fromJson({...doc.data(), 'sale_id': int.tryParse(doc.id)}),
    };

    for (var l in local) {
      if (l.saleId == null) continue;
      final r = remoteMap[l.saleId.toString()];

      if (r == null) {
        // Missing from Firebase
        if (l.isSynced) {
          // Cloud deletion
          print(
            '🗑️ [FirebaseSync] Deleting local sale ${l.saleId} (cloud deletion)',
          );
          await _sqlite.deleteSale(l.saleId!);
        } else {
          // New local sale
          print('📤 [FirebaseSync] Uploading local sale: ${l.saleId}');
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('sales')
              .doc(syncedL.saleId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertSale(syncedL);
        }
      } else {
        // Exists in both
        if (_isLaterThan(l.updatedAt, r.updatedAt)) {
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('sales')
              .doc(syncedL.saleId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertSale(syncedL);
        } else if (_isLaterThan(r.updatedAt, l.updatedAt)) {
          final syncedR = r.copyWith(isSynced: true);
          await _sqlite.insertSale(syncedR);
        } else {
          if (!l.isSynced) {
            await _sqlite.insertSale(l.copyWith(isSynced: true));
          }
        }
      }
      remoteMap.remove(l.saleId.toString());
    }
    // New from Firebase
    for (var r in remoteMap.values) {
      print('📥 [FirebaseSync] Downloading remote sale: ${r.saleId}');
      await _sqlite.insertSale(r.copyWith(isSynced: true));
    }
  }

  Future<void> _integrateFinancePayments() async {
    final local = await _sqlite.listFinancePayments();
    final remoteSnap = await _firestore.collection('finance_payments').get();
    final remoteMap = {
      for (var doc in remoteSnap.docs)
        doc.id: FinancePayment.fromJson({
          ...doc.data(),
          'payment_id': int.tryParse(doc.id),
        }),
    };

    for (var l in local) {
      if (l.paymentId == null) continue;
      final r = remoteMap[l.paymentId.toString()];

      if (r == null) {
        // Missing from Firebase
        if (l.isSynced) {
          // Cloud deletion
          print(
            '🗑️ [FirebaseSync] Deleting local finance payment ${l.paymentId} (cloud deletion)',
          );
          await _sqlite.deleteFinancePayment(l.paymentId!);
        } else {
          // New local finance payment
          print(
            '📤 [FirebaseSync] Uploading local finance payment: ${l.paymentId}',
          );
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('finance_payments')
              .doc(syncedL.paymentId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertFinancePayment(syncedL);
        }
      } else {
        // Exists in both
        if (_isLaterThan(l.updatedAt, r.updatedAt)) {
          final syncedL = l.copyWith(isSynced: true);
          await _firestore
              .collection('finance_payments')
              .doc(syncedL.paymentId.toString())
              .set(syncedL.toJson());
          await _sqlite.insertFinancePayment(syncedL);
        } else if (_isLaterThan(r.updatedAt, l.updatedAt)) {
          final syncedR = r.copyWith(isSynced: true);
          await _sqlite.insertFinancePayment(syncedR);
        } else {
          if (!l.isSynced) {
            await _sqlite.insertFinancePayment(l.copyWith(isSynced: true));
          }
        }
      }
      remoteMap.remove(l.paymentId.toString());
    }
    // New from Firebase
    for (var r in remoteMap.values) {
      print(
        '📥 [FirebaseSync] Downloading remote finance payment: ${r.paymentId}',
      );
      await _sqlite.insertFinancePayment(r.copyWith(isSynced: true));
    }
  }
}
