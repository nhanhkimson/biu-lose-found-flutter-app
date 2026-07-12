import 'package:beltei_app/core/utils/firestore_helpers.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `notifications` collection.
class NotificationsStore {
  NotificationsStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const collection = 'notifications';

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(collection);

  AppNotification _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      kind: data['kind'] as String? ?? 'info',
      link: data['link'] as String?,
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: firestoreDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  Future<int> countUnread(String userId) async {
    final snapshot = await _col
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<({List<AppNotification> notifications, int unreadCount})> fetchForUser({
    required String userId,
    int limit = 50,
  }) async {
    final snapshot = await _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final notifications = snapshot.docs.map(_fromDoc).toList();
    final unreadCount = await countUnread(userId);
    return (notifications: notifications, unreadCount: unreadCount);
  }

  Future<void> markAllRead(String userId) async {
    final snapshot = await _col
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> markRead(String userId, List<String> ids) async {
    if (ids.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.update(_col.doc(id), {'read': true});
    }
    await batch.commit();
  }

  Future<void> create({
    required String userId,
    required String kind,
    required String title,
    required String message,
    String? link,
  }) async {
    await _col.add({
      'userId': userId,
      'kind': kind,
      'title': title,
      'message': message,
      if (link != null) 'link': link,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
