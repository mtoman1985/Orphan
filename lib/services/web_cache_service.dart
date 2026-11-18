import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child.dart';
import '../models/sponsor.dart';
import '../models/payment.dart';
import 'github_storage_service.dart';

/// Service for caching Firebase data on web to improve performance
class WebCacheService {
  static final WebCacheService _instance = WebCacheService._internal();
  factory WebCacheService() => _instance;
  WebCacheService._internal();

  // In-memory cache for children
  List<Child>? _cachedChildren;
  DateTime? _cacheTime;

  // In-memory cache for sponsors
  List<Sponsor>? _cachedSponsors;
  DateTime? _sponsorsCacheTime;
  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _childrenSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _sponsorsSubscription;

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  void startRealtimeUpdates() {
    _childrenSubscription ??= FirebaseFirestore.instance
        .collection('children')
        .snapshots()
        .listen(
          (snapshot) => unawaited(_acceptChildrenSnapshot(snapshot)),
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('❌ [WebCache] Children listener failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
    _sponsorsSubscription ??= FirebaseFirestore.instance
        .collection('sponsors')
        .snapshots()
        .listen(
          _acceptSponsorsSnapshot,
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('❌ [WebCache] Sponsors listener failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  Future<void> _acceptChildrenSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    try {
      final children = <Child>[];
      for (final doc in snapshot.docs) {
        final child = Child.fromJson({...doc.data(), 'id': doc.id});
        await GitHubStorageService.fixChildPaths(child);
        children.add(child);
      }
      _cachedChildren = children;
      _cacheTime = DateTime.now();
      revision.value++;
    } catch (error, stackTrace) {
      debugPrint('❌ [WebCache] Failed to apply children update: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _acceptSponsorsSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    try {
      _cachedSponsors =
          snapshot.docs.map((doc) {
            return Sponsor.fromJson({...doc.data(), 'id': doc.id});
          }).toList();
      _sponsorsCacheTime = DateTime.now();
      revision.value++;
    } catch (error, stackTrace) {
      debugPrint('❌ [WebCache] Failed to apply sponsors update: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Get children from cache or Firebase
  Future<List<Child>> getChildren({bool forceRefresh = false}) async {
    // Check if cache is valid
    if (!forceRefresh &&
        _cachedChildren != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      debugPrint(
        '📦 [WebCache] Returning cached children (${_cachedChildren!.length} items)',
      );
      return _cachedChildren!;
    }

    // Fetch from Firebase
    debugPrint('🔄 [WebCache] Fetching children from Firebase...');
    final children = await _fetchChildrenFromFirebase();

    // Update cache
    _cachedChildren = children;
    _cacheTime = DateTime.now();

    debugPrint('✅ [WebCache] Cached ${children.length} children');
    return children;
  }

  /// Get sponsors from cache or Firebase
  Future<List<Sponsor>> getSponsors({bool forceRefresh = false}) async {
    // Check if cache is valid
    if (!forceRefresh &&
        _cachedSponsors != null &&
        _sponsorsCacheTime != null &&
        DateTime.now().difference(_sponsorsCacheTime!) < _cacheDuration) {
      debugPrint(
        '📦 [WebCache] Returning cached sponsors (${_cachedSponsors!.length} items)',
      );
      return _cachedSponsors!;
    }

    // Fetch from Firebase
    debugPrint('🔄 [WebCache] Fetching sponsors from Firebase...');
    final sponsors = await _fetchSponsorsFromFirebase();

    // Update cache
    _cachedSponsors = sponsors;
    _sponsorsCacheTime = DateTime.now();

    debugPrint('✅ [WebCache] Cached ${sponsors.length} sponsors');
    return sponsors;
  }

  /// Fetch children from Firebase
  Future<List<Child>> _fetchChildrenFromFirebase() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('children').get();

      final children = <Child>[];
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        try {
          final child = Child.fromJson(data);
          GitHubStorageService.fixChildPaths(child);
          children.add(child);
        } catch (e, stackTrace) {
          debugPrint(
            '❌ [WebCache] Failed to parse child ${doc.id}: $e\n$stackTrace',
          );
          rethrow;
        }
      }

      return children;
    } catch (e) {
      debugPrint('❌ [WebCache] Error fetching children: $e');
      rethrow;
    }
  }

  /// Get total payments count from Firebase (for stats)
  Future<int> getTotalPaymentsCount() async {
    try {
      // Use collectionGroup to count all payments across all children
      final snapshot =
          await FirebaseFirestore.instance.collectionGroup('payments').get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ [WebCache] Error fetching total payments count: $e');
      return 0;
    }
  }

  /// Fetch sponsors from Firebase
  Future<List<Sponsor>> _fetchSponsorsFromFirebase() async {
    try {
      debugPrint('🔍 [WebCache] Starting to fetch sponsors from Firebase...');

      final snapshot =
          await FirebaseFirestore.instance.collection('sponsors').get();

      debugPrint(
        '📊 [WebCache] Found ${snapshot.docs.length} sponsor documents',
      );

      if (snapshot.docs.isEmpty) {
        debugPrint(
          '⚠️ [WebCache] No sponsors found in Firebase collection "sponsors"',
        );
        return [];
      }

      final sponsors =
          snapshot.docs.map((doc) {
            debugPrint('📄 [WebCache] Processing sponsor doc: ${doc.id}');
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            debugPrint('📝 [WebCache] Sponsor data: $data');

            try {
              final sponsor = Sponsor.fromJson(data);
              debugPrint(
                '✅ [WebCache] Successfully parsed sponsor: ${sponsor.name}',
              );
              return sponsor;
            } catch (e) {
              debugPrint('❌ [WebCache] Error parsing sponsor ${doc.id}: $e');
              rethrow;
            }
          }).toList();

      debugPrint(
        '✅ [WebCache] Successfully fetched ${sponsors.length} sponsors',
      );
      return sponsors;
    } catch (e, stackTrace) {
      debugPrint('❌ [WebCache] Error fetching sponsors: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedChildren = null;
    _cacheTime = null;
    _cachedSponsors = null;
    _sponsorsCacheTime = null;
    revision.value++;
    debugPrint('🗑️ [WebCache] Cache cleared');
  }

  /// Update a single child in cache
  void updateChildInCache(Child child) {
    if (_cachedChildren != null) {
      final index = _cachedChildren!.indexWhere((c) => c.id == child.id);
      if (index != -1) {
        _cachedChildren![index] = child;
        debugPrint('✅ [WebCache] Updated child ${child.id} in cache');
      } else {
        _cachedChildren!.add(child);
        debugPrint('✅ [WebCache] Added child ${child.id} to cache');
      }
      revision.value++;
    }
  }

  /// Remove a child from cache
  void removeChildFromCache(String childId) {
    if (_cachedChildren != null) {
      _cachedChildren!.removeWhere((c) => c.id == childId);
      debugPrint('✅ [WebCache] Removed child $childId from cache');
      revision.value++;
    }
  }

  /// Update a single sponsor in cache
  void updateSponsorInCache(Sponsor sponsor) {
    if (_cachedSponsors != null) {
      final index = _cachedSponsors!.indexWhere((s) => s.id == sponsor.id);
      if (index != -1) {
        _cachedSponsors![index] = sponsor;
        debugPrint('✅ [WebCache] Updated sponsor ${sponsor.id} in cache');
      } else {
        _cachedSponsors!.add(sponsor);
        debugPrint('✅ [WebCache] Added sponsor ${sponsor.id} to cache');
      }
      revision.value++;
    }
  }

  /// Get payments for a specific sponsor from Firebase
  Future<List<Payment>> getPaymentsForSponsor(String sponsorId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collectionGroup('payments')
              .where('sponsorId', isEqualTo: sponsorId)
              .get();

      return snapshot.docs.map((doc) => Payment.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint(
        '❌ [WebCache] Error fetching payments for sponsor $sponsorId: $e',
      );
      return [];
    }
  }

  /// Remove a sponsor from cache
  void removeSponsorFromCache(String sponsorId) {
    if (_cachedSponsors != null) {
      _cachedSponsors!.removeWhere((s) => s.id == sponsorId);
      debugPrint('✅ [WebCache] Removed sponsor $sponsorId from cache');
      revision.value++;
    }
  }
}
