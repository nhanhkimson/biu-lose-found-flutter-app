import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/data/firebase/claims_store.dart';
import 'package:beltei_app/data/firebase/items_store.dart';
import 'package:beltei_app/data/firebase/notifications_store.dart';
import 'package:beltei_app/data/models/claim_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClaimsRepository {
  ClaimsRepository(
    this._claims,
    this._items,
    this._notifications, {
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final ClaimsStore _claims;
  final ItemsStore _items;
  final NotificationsStore _notifications;
  final FirebaseAuth _auth;

  String? get _userId => _auth.currentUser?.uid;

  Future<ClaimsPage> fetchMyClaims({
    int page = 1,
    String? status,
  }) async {
    final uid = _userId;
    if (uid == null) throw ApiException('Sign in to view your claims.');
    return _claims.queryByUser(userId: uid, page: page, status: status);
  }

  Future<String> submitClaim({
    required String itemId,
    required String message,
    List<String> proofImageUrls = const [],
  }) async {
    final uid = _userId;
    if (uid == null) throw ApiException('Sign in to submit a claim.');

    final itemData = await _items.getRaw(itemId);
    if (itemData == null) throw ApiException('Item not found.');

    final itemOwnerId = itemData['userId'] as String?;
    final itemSnapshot = {
      'id': itemId,
      'title': itemData['title'],
      'type': itemData['type'],
      'status': itemData['status'],
      'imageUrl': itemData['imageUrl'],
    };

    final claimId = await _claims.create(
      userId: uid,
      itemId: itemId,
      message: message,
      itemSnapshot: itemSnapshot,
      proofImageUrls: proofImageUrls,
    );

    if (itemOwnerId != null && itemOwnerId.isNotEmpty && itemOwnerId != uid) {
      await _notifications.create(
        userId: itemOwnerId,
        kind: 'claim',
        title: 'New claim on your listing',
        message: 'Someone submitted a claim for "${itemData['title']}".',
        link: '/items/$itemId',
      );
    }

    return claimId;
  }
}
