import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/data/firebase/items_store.dart';
import 'package:beltei_app/data/local/items_cache.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final key = ItemsCache.cacheKey(page: page, type: type, q: q, category: category);
    if (!mine && preferCache && page == 1) {
      final cached = await _cache.get(key);
      if (cached != null) return cached;
    }

    if (mine) {
      final uid = _userId;
      if (uid == null) throw ApiException('Sign in to view your items.');
    }

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
  }

  Future<ItemsPage> fetchMyItems({
    int page = 1,
    String? type,
    String? status,
  }) =>
      fetchItems(page: page, type: type, status: status, mine: true, preferCache: false);

  Future<LostFoundItem> fetchDetail(String id) async {
    final item = await _store.getDetail(id);
    if (item == null) throw ApiException('Item not found.');
    return item;
  }

  Future<List<LostFoundItem>> fetchSimilar(String id) async {
    return _store.findSimilar(id);
  }

  Future<String> createItem(Map<String, dynamic> payload) async {
    final uid = _userId;
    if (uid == null) throw ApiException('Sign in to publish a listing.');
    return _store.create(uid, payload);
  }

  Future<LostFoundItem> updateStatus(String id, String status) async {
    return _store.updateStatus(id, status);
  }
}
