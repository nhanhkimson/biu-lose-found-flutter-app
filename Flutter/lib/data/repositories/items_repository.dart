import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/core/utils/firebase_firestore_errors.dart';
import 'package:beltei_app/data/firebase/items_store.dart';
import 'package:beltei_app/data/local/items_cache.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ItemsRepository {
  ItemsRepository(this._store, this._cache, {FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final ItemsStore _store;
  final ItemsCache _cache;
  final FirebaseAuth _auth;

  String? get _userId => _auth.currentUser?.uid;

  Future<ItemsPage> fetchItems({
    int page = 1,
    String? q,
    String? type,
    String? category,
    String? building,
    String? status,
    String? dateFrom,
    String? dateTo,
    bool mine = false,
    bool preferCache = true,
  }) async {
    final key = ItemsCache.cacheKey(
      page: page,
      type: type,
      q: q,
      category: category,
      building: building,
      status: status,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    if (!mine && preferCache && page == 1) {
      final cached = await _cache.get(key);
      if (cached != null) return cached;
    }

    if (mine) {
      final uid = _userId;
      if (uid == null) throw ApiException('Sign in to view your items.');
    }

    try {
      final result = await _store.queryItems(
        page: page,
        q: q,
        type: type,
        category: category,
        building: building,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
        userId: mine ? _userId : null,
      );

      if (!mine && page == 1) {
        await _cache.put(key, result);
      }
      return result;
    } on FirebaseException catch (e) {
      throw ApiException(mapFirestoreError(e));
    }
  }

  Future<ItemsPage> fetchMyItems({
    int page = 1,
    String? type,
    String? status,
  }) =>
      fetchItems(page: page, type: type, status: status, mine: true, preferCache: false);

  Future<LostFoundItem> fetchDetail(String id) async {
    try {
      return await _store.getDetail(id);
    } on StateError {
      throw ApiException('Item not found.');
    } on FirebaseException catch (e) {
      throw ApiException(mapFirestoreError(e));
    }
  }

  Future<List<LostFoundItem>> fetchSimilar(String id) async {
    return _store.findSimilar(id);
  }

  Future<String> createItem(Map<String, dynamic> payload) async {
    final uid = _userId;
    if (uid == null) throw ApiException('Sign in to publish a listing.');
    final id = await _store.create(uid, payload);
    await _cache.clear();
    return id;
  }

  Future<LostFoundItem> updateStatus(String id, String status) async {
    final uid = _userId;
    if (uid == null) throw ApiException('Sign in to update item status.');

    final raw = await _store.getRaw(id);
    if (raw == null) throw ApiException('Item not found.');
    if (raw['userId'] != uid) {
      throw ApiException('You can only update your own listings.');
    }

    final updated = await _store.updateStatus(id, status);
    await _cache.clear();
    return updated;
  }
}
