import 'package:beltei_app/core/utils/firestore_helpers.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `items` collection.
class ItemsStore {
  ItemsStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const collection = 'items';
  static const pageSize = 20;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(collection);

  LostFoundItem _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final imageUrls = data['imageUrls'];
    return LostFoundItem(
      id: doc.id,
      type: data['type'] as String? ?? 'LOST',
      status: data['status'] as String?,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      category: data['category'] as String? ?? '',
      building: data['building'] as String? ?? '',
      roomHint: data['roomHint'] as String?,
      eventDate: firestoreDate(data['eventDate']) ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      imageUrls: imageUrls is List
          ? imageUrls.map((e) => e.toString()).toList()
          : const [],
      color: data['color'] as String?,
      brand: data['brand'] as String?,
      timeApprox: data['timeApprox'] as String?,
      foundDisposition: data['foundDisposition'] as String?,
      reward: data['reward'] as String?,
      viewCount: data['viewCount'] as int?,
      createdAt: firestoreDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  Future<ItemsPage> queryItems({
    int page = 1,
    String? q,
    String? type,
    String? category,
    String? building,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? userId,
  }) async {
    Query<Map<String, dynamic>> query = _col;
    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }
    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    final filtered = snapshot.docs.where((doc) {
      final data = doc.data();
      return matchesItemFilters(
        data,
        q: q,
        type: type,
        category: category,
        building: building,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    }).toList();

    final total = filtered.length;
    final totalPages = total == 0 ? 1 : ((total + pageSize - 1) / pageSize).ceil();
    final pageDocs = paginateList(filtered, page: page, pageSize: pageSize);

    return ItemsPage(
      items: pageDocs.map(_fromDoc).toList(),
      total: total,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  Future<LostFoundItem?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  Future<LostFoundItem> getDetail(String id) async {
    final item = await getById(id);
    if (item == null) throw StateError('Item not found.');
    await _col.doc(id).update({'viewCount': FieldValue.increment(1)});
    return item.copyWith(viewCount: (item.viewCount ?? 0) + 1);
  }

  Future<List<LostFoundItem>> findSimilar(String id) async {
    final source = await getById(id);
    if (source == null) return const [];

    final opposite = source.type == 'LOST' ? 'FOUND' : 'LOST';
    final snapshot = await _col
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    return snapshot.docs
        .map(_fromDoc)
        .where((item) =>
            item.id != id &&
            item.type == opposite &&
            item.status == 'OPEN' &&
            item.category == source.category &&
            item.building == source.building)
        .take(5)
        .toList();
  }

  Future<String> create(String userId, Map<String, dynamic> payload) async {
    final imageUrls = payload['imageUrls'];
    final urls = imageUrls is List
        ? imageUrls.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final doc = _col.doc();
    await doc.set({
      'userId': userId,
      'type': payload['type'],
      'title': payload['title'],
      'description': payload['description'],
      'category': payload['category'],
      'color': payload['color'] ?? '',
      'brand': payload['brand'] ?? '',
      'building': payload['building'],
      'roomHint': payload['roomHint'],
      'eventDate': payload['eventDate'],
      'timeApprox': payload['timeApprox'] ?? '',
      'foundDisposition': payload['foundDisposition'],
      'imageUrls': urls,
      'imageUrl': urls.isNotEmpty ? urls.first : null,
      'reward': payload['reward'] ?? '',
      'notifyOnMatch': payload['notifyOnMatch'] ?? true,
      'allowContact': payload['allowContact'] ?? true,
      'status': 'OPEN',
      'viewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<LostFoundItem> updateStatus(String id, String status) async {
    await _col.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final item = await getById(id);
    if (item == null) throw StateError('Item not found.');
    return item.copyWith(status: status);
  }

  Future<Map<String, dynamic>?> getRaw(String id) async {
    final doc = await _col.doc(id).get();
    return doc.data();
  }

  ItemsPage toItemsPage(List<LostFoundItem> items, {int page = 1}) {
    return ItemsPage(
      items: items,
      total: items.length,
      page: page,
      pageSize: items.length,
      totalPages: 1,
    );
  }
}

extension on LostFoundItem {
  LostFoundItem copyWith({
    String? status,
    int? viewCount,
  }) {
    return LostFoundItem(
      id: id,
      type: type,
      title: title,
      category: category,
      building: building,
      roomHint: roomHint,
      eventDate: eventDate,
      imageUrl: imageUrl,
      createdAt: createdAt,
      status: status ?? this.status,
      description: description,
      imageUrls: imageUrls,
      color: color,
      brand: brand,
      timeApprox: timeApprox,
      foundDisposition: foundDisposition,
      reward: reward,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}
