import 'package:beltei_app/core/utils/firestore_helpers.dart';
import 'package:beltei_app/data/models/claim_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `claims` collection.
class ClaimsStore {
  ClaimsStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const collection = 'claims';
  static const pageSize = 20;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(collection);

  ClaimItem _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final item = data['item'] as Map<String, dynamic>? ?? {};
    final proof = data['proofImageUrls'];
    return ClaimItem(
      id: doc.id,
      status: data['status'] as String? ?? 'PENDING',
      type: data['type'] as String? ?? 'CLAIM',
      message: data['message'] as String? ?? '',
      createdAt: firestoreDate(data['createdAt']) ?? DateTime.now(),
      itemId: item['id'] as String? ?? data['itemId'] as String? ?? '',
      itemTitle: item['title'] as String? ?? '',
      itemType: item['type'] as String? ?? '',
      itemStatus: item['status'] as String? ?? '',
      itemImageUrl: item['imageUrl'] as String?,
      adminNote: data['adminNote'] as String?,
      proofImageUrls: proof is List
          ? proof.map((e) => e.toString()).toList()
          : const [],
      reviewedAt: firestoreDate(data['reviewedAt']),
    );
  }

  Future<ClaimsPage> queryByUser({
    required String userId,
    int page = 1,
    String? status,
  }) async {
    Query<Map<String, dynamic>> query =
        _col.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    final filtered = snapshot.docs.where((doc) {
      if (status == null || status.isEmpty) return true;
      return doc.data()['status'] == status;
    }).toList();

    final total = filtered.length;
    final totalPages = total == 0 ? 1 : ((total + pageSize - 1) / pageSize).ceil();
    final pageDocs = paginateList(filtered, page: page, pageSize: pageSize);

    return ClaimsPage(
      claims: pageDocs.map(_fromDoc).toList(),
      total: total,
      page: page,
      totalPages: totalPages,
    );
  }

  Future<String> create({
    required String userId,
    required String itemId,
    required String message,
    required Map<String, dynamic> itemSnapshot,
    List<String> proofImageUrls = const [],
  }) async {
    final doc = _col.doc();
    await doc.set({
      'userId': userId,
      'itemId': itemId,
      'message': message.trim(),
      'proofImageUrls': proofImageUrls,
      'status': 'PENDING',
      'type': 'CLAIM',
      'item': itemSnapshot,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
}
