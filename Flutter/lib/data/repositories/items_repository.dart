import 'package:beltei_app/core/network/api_client.dart';
import 'package:beltei_app/data/local/items_cache.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';

class ItemsRepository {
  ItemsRepository(this._api, this._cache);

  final ApiClient _api;
  final ItemsCache _cache;

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

    final query = <String, String>{
      'page': '$page',
      if (mine) 'mine': 'true',
      if (q != null && q.isNotEmpty) 'q': q,
      if (type != null && type.isNotEmpty) 'type': type,
      if (category != null && category.isNotEmpty) 'category': category,
      if (building != null && building.isNotEmpty) 'building': building,
      if (status != null && status.isNotEmpty) 'status': status,
      if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
    };

    final json = await _api.get(
      '/api/items',
      query: query,
      auth: mine,
    );
    final result = ItemsPage.fromJson(json);
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
    final json = await _api.get('/api/items/$id');
    return LostFoundItem.fromDetailJson(json);
  }

  Future<List<LostFoundItem>> fetchSimilar(String id) async {
    final json = await _api.get('/api/items/$id/similar');
    final list = json['items'] as List<dynamic>? ?? [];
    return list
        .map((e) => LostFoundItem.fromListJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> createItem(Map<String, dynamic> payload) async {
    final json = await _api.post('/api/items', body: payload, auth: true);
    return json['id'] as String;
  }

  Future<LostFoundItem> updateStatus(String id, String status) async {
    final json = await _api.patch('/api/items/$id', body: {'status': status});
    return LostFoundItem.fromDetailJson(json);
  }
}
