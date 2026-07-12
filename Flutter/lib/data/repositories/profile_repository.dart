import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/core/storage/session_store.dart';
import 'package:beltei_app/core/utils/firebase_auth_errors.dart';
import 'package:beltei_app/core/utils/user_photo_url.dart';
import 'package:beltei_app/data/firebase/storage_upload_store.dart';
import 'package:beltei_app/data/firebase/user_profile_store.dart';
import 'package:beltei_app/data/models/app_user.dart';
import 'package:beltei_app/data/models/profile_activity.dart';
import 'package:beltei_app/data/repositories/claims_repository.dart';
import 'package:beltei_app/data/repositories/items_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileRepository {
  ProfileRepository(
    this._session,
    this._items,
    this._claims, {
    UserProfileStore? profileStore,
    FirebaseAuth? auth,
    StorageUploadStore? storage,
  })  : _profileStore = profileStore ?? UserProfileStore(),
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? StorageUploadStore();

  final SessionStore _session;
  final ItemsRepository _items;
  final ClaimsRepository _claims;
  final UserProfileStore _profileStore;
  final FirebaseAuth _auth;
  final StorageUploadStore _storage;

  AppUser _mapUser(
    User firebaseUser,
    Map<String, dynamic>? firestore, {
    ProfileStats? stats,
    List<ProfileActivity>? activity,
    String? fallbackImage,
  }) {
    final usesPassword = firebaseUser.providerData
        .any((provider) => provider.providerId == 'password');
    final extra = firestore ?? {};
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      name: extra['name'] as String? ?? firebaseUser.displayName,
      phoneNumber: extra['phone'] as String? ?? firebaseUser.phoneNumber,
      image: resolveUserPhotoUrl(firebaseUser) ??
          readStoredPhotoUrl(extra) ??
          fallbackImage,
      studentId: extra['studentId'] as String?,
      role: extra['role'] as String? ?? 'STUDENT',
      stats: stats,
      createdAt: firebaseUser.metadata.creationTime,
      lastSignInAt: firebaseUser.metadata.lastSignInTime,
      emailVerified: firebaseUser.emailVerified,
      hasPassword: usesPassword,
      recentActivity: activity ?? const [],
    );
  }

  Future<User> _requireUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw ApiException('Not signed in.');
    }
    await firebaseUser.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null) {
      throw ApiException('Not signed in.');
    }
    return refreshed;
  }

  Future<void> _persistSession(AppUser user) async {
    await _session.saveSession(user: user);
  }

  Future<ProfileStats> _fetchStats() async {
    try {
      final lostPage = await _items.fetchMyItems(type: 'LOST');
      final foundPage = await _items.fetchMyItems(type: 'FOUND');
      final claimsPage = await _claims.fetchMyClaims();
      final resolvedLost =
          await _items.fetchMyItems(type: 'LOST', status: 'RESOLVED');
      final resolvedFound =
          await _items.fetchMyItems(type: 'FOUND', status: 'RESOLVED');

      return ProfileStats(
        myLost: lostPage.total,
        myFound: foundPage.total,
        myClaims: claimsPage.total,
        myResolved: resolvedLost.total + resolvedFound.total,
      );
    } catch (_) {
      return const ProfileStats(
        myLost: 0,
        myFound: 0,
        myClaims: 0,
        myResolved: 0,
      );
    }
  }

  Future<List<ProfileActivity>> _fetchRecentActivity() async {
    try {
      final itemsPage = await _items.fetchMyItems();
      final claimsPage = await _claims.fetchMyClaims();

      final activities = <ProfileActivity>[
        for (final item in itemsPage.items)
          ProfileActivity(
            id: item.id,
            kind: 'item',
            itemId: item.id,
            title: item.title,
            type: item.type,
            status: item.status,
            at: item.createdAt,
          ),
        for (final claim in claimsPage.claims)
          ProfileActivity(
            id: claim.id,
            kind: 'claim',
            itemId: claim.itemId,
            title: claim.itemTitle,
            claimStatus: claim.status,
            at: claim.createdAt,
          ),
      ];
      activities.sort((a, b) => b.at.compareTo(a.at));
      return activities.take(10).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>?> _loadExtendedProfile(String uid) async {
    final firestore = await _profileStore.get(uid);
    if (firestore != null) return firestore;

    final cached = await _session.user;
    if (cached == null || cached.id != uid) return null;

    return {
      if (cached.studentId != null && cached.studentId!.isNotEmpty)
        'studentId': cached.studentId,
      if (cached.phoneNumber != null && cached.phoneNumber!.isNotEmpty)
        'phone': cached.phoneNumber,
      if (cached.role != null) 'role': cached.role,
      if (cached.image != null && cached.image!.isNotEmpty)
        'photoUrl': cached.image,
    };
  }

  Future<AppUser> fetchProfile() async {
    var firebaseUser = await _requireUser();
    final cached = await _session.user;
    final firestore = await _loadExtendedProfile(firebaseUser.uid);
    final storedPhoto = readStoredPhotoUrl(firestore) ?? cached?.image;
    if (storedPhoto == null && userHasFacebookProvider(firebaseUser)) {
      firebaseUser = await ensureFacebookPhotoSynced(firebaseUser);
    }
    final fallbackImage =
        storedPhoto ?? (cached?.id == firebaseUser.uid ? cached?.image : null);
    final stats = await _fetchStats();
    final activity = await _fetchRecentActivity();
    final user = _mapUser(
      firebaseUser,
      firestore,
      stats: stats,
      activity: activity,
      fallbackImage: fallbackImage,
    );
    await _persistSession(user);
    return user;
  }

  Future<AppUser> updateProfile({
    required String name,
    String? studentId,
    String? imageUrl,
  }) async {
    final firebaseUser = await _requireUser();

    await firebaseUser.updateDisplayName(name.trim());

    final trimmedImage = imageUrl?.trim();
    if (trimmedImage != null && trimmedImage.isNotEmpty) {
      await firebaseUser.updatePhotoURL(trimmedImage);
    }

    final trimmedStudent = studentId?.trim();
    final synced = await _profileStore.merge(
      firebaseUser.uid,
      {
        'studentId': trimmedStudent?.isNotEmpty == true ? trimmedStudent : '',
        'role': 'STUDENT',
      },
    );

    final user = await fetchProfile();
    if (!synced) {
      final withStudent = AppUser(
        id: user.id,
        email: user.email,
        name: user.name,
        phoneNumber: user.phoneNumber,
        role: user.role,
        image: user.image,
        studentId: trimmedStudent?.isNotEmpty == true ? trimmedStudent : user.studentId,
        stats: user.stats,
        createdAt: user.createdAt,
        lastSignInAt: user.lastSignInAt,
        emailVerified: user.emailVerified,
        hasPassword: user.hasPassword,
        recentActivity: user.recentActivity,
      );
      await _persistSession(withStudent);
      return withStudent;
    }
    return user;
  }

  Future<String> uploadAvatarFile(XFile file) async {
    final firebaseUser = await _requireUser();
    return _storage.uploadAvatarFile(file, firebaseUser.uid);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      throw ApiException('Passwords do not match.');
    }
    if (newPassword.length < 8) {
      throw ApiException('New password must be at least 8 characters.');
    }

    final firebaseUser = await _requireUser();
    final email = firebaseUser.email;
    if (email == null || email.isEmpty) {
      throw ApiException('This account has no email for password change.');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      await firebaseUser.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw ApiException(mapFirebaseAuthError(e));
    }
  }
}
