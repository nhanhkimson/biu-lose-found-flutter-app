import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/core/storage/session_store.dart';
import 'package:beltei_app/core/utils/user_photo_url.dart';
import 'package:beltei_app/data/firebase/user_profile_store.dart';
import 'package:beltei_app/data/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthRepository {
  AuthRepository(this._session, {UserProfileStore? profileStore})
      : _profileStore = profileStore ?? UserProfileStore();

  final SessionStore _session;
  final UserProfileStore _profileStore;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AppUser _mapUser(
    User firebaseUser, {
    String? studentId,
    String? phone,
    String? role,
    String? imageUrl,
    String? name,
  }) {
    final usesPassword = firebaseUser.providerData
        .any((provider) => provider.providerId == 'password');
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      name: name ?? firebaseUser.displayName,
      phoneNumber: phone ?? firebaseUser.phoneNumber,
      image: imageUrl ?? resolveUserPhotoUrl(firebaseUser),
      studentId: studentId,
      role: role ?? 'STUDENT',
      createdAt: firebaseUser.metadata.creationTime,
      lastSignInAt: firebaseUser.metadata.lastSignInTime,
      emailVerified: firebaseUser.emailVerified,
      hasPassword: usesPassword,
    );
  }

  Future<void> _persistUser(
    User firebaseUser, {
    String? studentId,
    String? imageUrl,
    String? name,
  }) async {
    final idToken = await firebaseUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw ApiException('Failed to get auth token.');
    }
    final cached = await _session.user;
    final firestore = await _profileStore.get(firebaseUser.uid);
    final resolvedStudentId = studentId ??
        _readStudentId(firestore) ??
        cached?.studentId;
    final resolvedImage = imageUrl ??
        readStoredPhotoUrl(firestore) ??
        resolveUserPhotoUrl(firebaseUser) ??
        cached?.image;
    final user = _mapUser(
      firebaseUser,
      studentId: resolvedStudentId,
      phone: firestore?['phone'] as String? ?? cached?.phoneNumber,
      role: firestore?['role'] as String? ?? cached?.role,
      imageUrl: resolvedImage,
      name: name,
    );
    await _session.saveSession(sessionToken: idToken, user: user);
  }

  String? _readStudentId(Map<String, dynamic>? data) {
    final value = data?['studentId'] as String?;
    if (value != null && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw ApiException('Login failed. No user returned.');
    }

    await _persistUser(firebaseUser);
    return _mapUser(firebaseUser);
  }

  Future<void> _prepareIosFacebookLogin() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {
      // ATT unavailable on older iOS; Facebook may fall back to Limited Login.
    }
  }

  Future<AppUser> loginWithFacebook() async {
    await _prepareIosFacebookLogin();

    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
      loginTracking: LoginTracking.enabled,
    );

    if (result.status == LoginStatus.cancelled) {
      throw ApiException('Facebook sign-in was cancelled.');
    }
    if (result.status != LoginStatus.success) {
      throw ApiException(result.message ?? 'Facebook sign-in failed.');
    }

    final accessToken = result.accessToken;
    if (accessToken == null) {
      throw ApiException('Facebook sign-in failed: no access token.');
    }

    // Fetch Facebook profile immediately while the SDK session is active.
    final facebookProfile = await fetchFacebookProfile(accessToken);

    final AuthCredential credential;
    if (accessToken is LimitedToken) {
      credential = OAuthProvider('facebook.com').credential(
        idToken: accessToken.tokenString,
        rawNonce: accessToken.nonce,
      );
    } else {
      credential = FacebookAuthProvider.credential(accessToken.tokenString);
    }

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    User firebaseUser = userCredential.user!;

    final facebookName = facebookProfile?.name?.trim();
    if (facebookName != null &&
        facebookName.isNotEmpty &&
        (firebaseUser.displayName == null ||
            firebaseUser.displayName!.trim().isEmpty)) {
      await firebaseUser.updateDisplayName(facebookName);
    }

    final pictureUrl = facebookProfile?.pictureUrl;
    if (pictureUrl != null) {
      try {
        await firebaseUser.updatePhotoURL(pictureUrl);
        await firebaseUser.reload();
        firebaseUser = _firebaseAuth.currentUser ?? firebaseUser;
      } catch (_) {}
    }

    if (pictureUrl != null || facebookName != null) {
      await _profileStore.merge(
        firebaseUser.uid,
        {
          if (pictureUrl != null) 'photoUrl': pictureUrl,
          if (facebookName != null && facebookName.isNotEmpty) 'name': facebookName,
          'role': 'STUDENT',
        },
      );
    }

    await _persistUser(
      firebaseUser,
      imageUrl: pictureUrl ?? resolveUserPhotoUrl(firebaseUser),
      name: facebookName,
    );

    return _mapUser(
      firebaseUser,
      imageUrl: pictureUrl ?? resolveUserPhotoUrl(firebaseUser),
      name: facebookName,
    );
  }

  Future<AppUser?> fetchSessionUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final cached = await _session.user;
      await firebaseUser.reload();
      var refreshed = _firebaseAuth.currentUser ?? firebaseUser;
      final firestore = await _profileStore.get(refreshed.uid);
      final storedPhoto = readStoredPhotoUrl(firestore) ?? cached?.image;
      if (storedPhoto == null) {
        refreshed = await ensureFacebookPhotoSynced(refreshed);
      }
      await refreshed.getIdToken(true);
      await _persistUser(
        refreshed,
        studentId: cached?.studentId,
        imageUrl: storedPhoto ?? resolveUserPhotoUrl(refreshed) ?? cached?.image,
        name: cached?.name,
      );
      return _mapUser(
        refreshed,
        studentId: cached?.studentId,
        imageUrl: storedPhoto ?? resolveUserPhotoUrl(refreshed) ?? cached?.image,
        name: cached?.name,
      );
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? studentId,
  }) async {
    if (password != confirmPassword) {
      throw ApiException('Passwords do not match.');
    }

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw ApiException('Registration failed. No user returned.');
    }

    await firebaseUser.updateDisplayName(name.trim());
    await firebaseUser.reload();
    final refreshed = _firebaseAuth.currentUser ?? firebaseUser;
    final trimmedStudent =
        studentId?.trim().isNotEmpty == true ? studentId!.trim() : null;
    if (trimmedStudent != null) {
      await _profileStore.merge(refreshed.uid, {
        'studentId': trimmedStudent,
        'role': 'STUDENT',
      });
    }
    await _persistUser(refreshed, studentId: trimmedStudent);
    return _mapUser(refreshed, studentId: trimmedStudent);
  }

  Future<void> logout() async {
    await FacebookAuth.instance.logOut();
    await _firebaseAuth.signOut();
    await _session.clear();
  }

  Future<AppUser?> currentUser() async {
    final cached = await _session.user;
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      return _mapUser(
        firebaseUser,
        studentId: cached?.studentId,
        imageUrl: cached?.image ?? resolveUserPhotoUrl(firebaseUser),
        name: cached?.name,
      );
    }
    return cached;
  }

  Future<bool> isLoggedIn() async {
    if (_firebaseAuth.currentUser != null) return true;
    return _session.isLoggedIn;
  }
}
