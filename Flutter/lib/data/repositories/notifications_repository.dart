import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/data/firebase/notifications_store.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsRepository {
  NotificationsRepository(this._store, {FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final NotificationsStore _store;
  final FirebaseAuth _auth;

  String? get _userId => _auth.currentUser?.uid;

  Future<({List<AppNotification> notifications, int unreadCount})> fetch({
    int limit = 50,
  }) async {
    final uid = _userId;
    if (uid == null) throw ApiException('Sign in to view notifications.');
    return _store.fetchForUser(userId: uid, limit: limit);
  }

  Future<int> fetchUnreadCount() async {
    final uid = _userId;
    if (uid == null) return 0;
    return _store.countUnread(uid);
  }

  Future<void> markAllRead() async {
    final uid = _userId;
    if (uid == null) throw ApiException('Sign in to update notifications.');
    await _store.markAllRead(uid);
  }

  Future<void> markRead(List<String> ids) async {
    final uid = _userId;
    if (uid == null) throw ApiException('Sign in to update notifications.');
    await _store.markRead(uid, ids);
  }
}
