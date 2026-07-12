import 'package:beltei_app/core/utils/firebase_firestore_errors.dart';
import 'package:beltei_app/core/utils/firestore_helpers.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firestore `items` collection.
class ItemsStore {
  ItemsStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const collection = 'items';
  static const pageSize = 20;
  static const maxQueryLimit = 300;

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

  bool _needsIndexFallback(Object error) {
    if (error is FirebaseException) {
      return error.code == 'failed-precondition' ||
          isTransientFirestoreError(error);
    }
    return false;
  }

  Query<Map<String, dynamic>> _buildQuery({
    String? type,
    String? category,
    String? building,
    String? status,
    String? userId,
  }) {
    Query<Map<String, dynamic>> query = _col;

    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }
    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    if (building != null && building.isNotEmpty) {
      query = query.where('building', isEqualTo: building);
    }
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('createdAt', descending: true);
  }

  ItemsPage _pageFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required int page,
  }) {
    final total = docs.length;
    final totalPages =
        total == 0 ? 1 : ((total + pageSize - 1) / pageSize).ceil();
    final pageDocs = paginateList(docs, page: page, pageSize: pageSize);

    return ItemsPage(
      items: pageDocs.map(_fromDoc).toList(),
      total: total,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
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
    try {
      return await _queryItemsIndexed(
        page: page,
        q: q,
        type: type,
        category: category,
        building: building,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
        userId: userId,
      );
    } catch (e) {
      if (!_needsIndexFallback(e)) rethrow;
      return _queryItemsClientFallback(
        page: page,
        q: q,
        type: type,
        category: category,
        building: building,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
        userId: userId,
      );
    }
  }

  Future<ItemsPage> _queryItemsIndexed({
    required int page,
    String? q,
    String? type,
    String? category,
    String? building,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? userId,
  }) async {
    final query = _buildQuery(
      type: type,
      category: category,
      building: building,
      status: status,
      userId: userId,
    );

    final needsTextOrDateFilter = (q != null && q.isNotEmpty) ||
        (dateFrom != null && dateFrom.isNotEmpty) ||
        (dateTo != null && dateTo.isNotEmpty);
    final fetchLimit = needsTextOrDateFilter ? maxQueryLimit : pageSize * page;

    final snapshot = await query.limit(fetchLimit).get();
    final filtered = snapshot.docs.where((doc) {
      if (!needsTextOrDateFilter) return true;
      return matchesItemFilters(
        doc.data(),
        q: q,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    }).toList();

    return _pageFromDocs(filtered, page: page);
  }

  Future<ItemsPage> _queryItemsClientFallback({
    required int page,
    String? q,
    String? type,
    String? category,
    String? building,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? userId,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (userId != null && userId.isNotEmpty) {
      try {
        snapshot = await _col
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(maxQueryLimit)
            .get();
      } catch (_) {
        snapshot = await _col
            .orderBy('createdAt', descending: true)
            .limit(maxQueryLimit)
            .get();
      }
    } else {
      snapshot = await _col
          .orderBy('createdAt', descending: true)
          .limit(maxQueryLimit)
          .get();
    }

    final filtered = snapshot.docs.where((doc) {
      final data = doc.data();
      if (userId != null &&
          userId.isNotEmpty &&
          data['userId'] != userId) {
        return false;
      }
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

    return _pageFromDocs(filtered, page: page);
  }

  Future<LostFoundItem?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  Future<LostFoundItem> getDetail(String id) async {
    final item = await getById(id);
    if (item == null) throw StateError('Item not found.');

    try {
      await _col.doc(id).update({'viewCount': FieldValue.increment(1)});
      return item.copyWith(viewCount: (item.viewCount ?? 0) + 1);
    } catch (_) {
      return item;
    }
  }

  Future<List<LostFoundItem>> findSimilar(String id) async {
    final source = await getById(id);
    if (source == null) return const [];

    final opposite = source.type == 'LOST' ? 'FOUND' : 'LOST';
    try {
      final snapshot = await _col
          .where('type', isEqualTo: opposite)
          .where('status', isEqualTo: 'OPEN')
          .where('category', isEqualTo: source.category)
          .where('building', isEqualTo: source.building)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map(_fromDoc)
          .where((item) => item.id != id)
          .take(5)
          .toList();
    } catch (_) {
      final snapshot = await _col
          .orderBy('createdAt', descending: true)
          .limit(maxQueryLimit)
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
