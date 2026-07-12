import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/core/storage/session_store.dart';
import 'package:beltei_app/core/utils/auth_debug_log.dart';
import 'package:beltei_app/core/utils/user_photo_url.dart';
import 'package:beltei_app/data/firebase/user_profile_store.dart';
import 'package:beltei_app/data/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository(this._session, {UserProfileStore? profileStore})
      : _profileStore = profileStore ?? UserProfileStore();

  final SessionStore _session;
  final UserProfileStore _profileStore;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

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
    authLog('persistUser:start', 'uid=${firebaseUser.uid}');
    final cached = await _session.user;
    final firestore = await _profileStore.get(firebaseUser.uid);
    authLog('persistUser:firestoreRead', firestore == null ? 'null' : 'hasData');
    final resolvedStudentId = studentId ??
        _readStudentId(firestore) ??
        cached?.studentId;
    final resolvedImage = imageUrl ??
        readStoredPhotoUrl(firestore) ??
        resolveUserPhotoUrl(firebaseUser) ??
        cached?.image;
    final resolvedName = name ??
        firebaseUser.displayName ??
        firestore?['name'] as String? ??
        cached?.name;
    final resolvedRole =
        firestore?['role'] as String? ?? cached?.role ?? 'STUDENT';
    final resolvedPhone =
        firestore?['phone'] as String? ?? cached?.phoneNumber;
    final user = _mapUser(
      firebaseUser,
      studentId: resolvedStudentId,
      phone: resolvedPhone,
      role: resolvedRole,
      imageUrl: resolvedImage,
      name: resolvedName,
    );

    final merged = await _profileStore.merge(firebaseUser.uid, {
      if (resolvedName != null && resolvedName.trim().isNotEmpty)
        'name': resolvedName.trim(),
      if (firebaseUser.email != null && firebaseUser.email!.trim().isNotEmpty)
        'email': firebaseUser.email!.trim(),
      if (resolvedPhone != null && resolvedPhone.trim().isNotEmpty)
        'phone': resolvedPhone.trim(),
      if (resolvedImage != null && resolvedImage.trim().isNotEmpty)
        'photoUrl': resolvedImage.trim(),
      if (resolvedStudentId != null) 'studentId': resolvedStudentId,
      'role': resolvedRole,
    }).catchError((Object e) {
      authLog('persistUser:firestoreMergeError', e);
      return false;
    });
    authLog('persistUser:firestoreMerge', merged ? 'ok' : 'failed/skipped');

    final idToken = await firebaseUser.getIdToken();
    await _session.saveSession(
      user: user,
      sessionToken: idToken,
    );
    authLog(
      'persistUser:done',
      'uid=${user.id} name=${user.name} localSessionSaved=true',
    );
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

  Future<AppUser> loginWithGoogle() async {
    authLog('google:loginWithGoogle:start');

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        authLog('google:loginWithGoogle:cancelled');
        throw AuthCancelledException();
      }
      authLog('google:loginWithGoogle:failed', '${e.code}: ${e.description}');
      throw ApiException(e.description ?? 'Google sign-in failed.');
    }

    authLog('google:account', 'email=${googleUser.email} id=${googleUser.id}');
    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      authLog('google:loginWithGoogle:noIdToken');
      throw ApiException('Google sign-in failed: no ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    authLog('google:firebaseSignIn:start');
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    User firebaseUser = userCredential.user!;
    authLog(
      'google:firebaseSignIn:success',
      'uid=${firebaseUser.uid} email=${firebaseUser.email}',
    );

    final googleName = googleUser.displayName?.trim();
    final googlePhoto = googleUser.photoUrl;
    if (googleName != null &&
        googleName.isNotEmpty &&
        (firebaseUser.displayName == null ||
            firebaseUser.displayName!.trim().isEmpty)) {
      try {
        await firebaseUser.updateDisplayName(googleName);
      } catch (e) {
        authLog('google:updateDisplayName:error', e);
      }
    }
    if (googlePhoto != null &&
        googlePhoto.isNotEmpty &&
        (firebaseUser.photoURL == null || firebaseUser.photoURL!.isEmpty)) {
      try {
        await firebaseUser.updatePhotoURL(googlePhoto);
        await firebaseUser.reload();
        firebaseUser = _firebaseAuth.currentUser ?? firebaseUser;
      } catch (e) {
        authLog('google:updatePhotoURL:error', e);
      }
    }

    await _persistUser(
      firebaseUser,
      imageUrl: googlePhoto ?? resolveUserPhotoUrl(firebaseUser),
      name: googleName ?? firebaseUser.displayName,
    );

    final appUser = _mapUser(
      firebaseUser,
      imageUrl: googlePhoto ?? resolveUserPhotoUrl(firebaseUser),
      name: googleName ?? firebaseUser.displayName,
    );
    authLog('google:loginWithGoogle:done', 'uid=${appUser.id} name=${appUser.name}');
    return appUser;
  }

  Future<LoginTracking> _facebookLoginTracking() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return LoginTracking.enabled;
    }

    try {
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
      if (status != TrackingStatus.authorized) {
        return LoginTracking.limited;
      }
    } catch (_) {
      return LoginTracking.limited;
    }

    return LoginTracking.enabled;
  }

  Future<LoginResult> _requestFacebookLogin() async {
    final loginTracking = await _facebookLoginTracking();
    final loginBehavior = LoginBehavior.nativeWithFallback;

    authLog(
      'facebook:requestLogin',
      'platform=$defaultTargetPlatform tracking=$loginTracking behavior=$loginBehavior',
    );

    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
      loginTracking: loginTracking,
      loginBehavior: loginBehavior,
    );

    authLog(
      'facebook:loginResult',
      'status=${result.status} message=${result.message} hasToken=${result.accessToken != null}',
    );

    if (result.status == LoginStatus.cancelled) {
      // Android sometimes reports "cancelled" even after a successful redirect.
      final cached = await FacebookAuth.instance.accessToken;
      authLog(
        'facebook:cancelledRecovery',
        cached == null
            ? 'no cached token'
            : 'recovered type=${cached.type} token=${authTokenSummary(cached.tokenString)}',
      );
      if (cached != null) {
        return LoginResult(status: LoginStatus.success, accessToken: cached);
      }
    }

    return result;
  }

  AuthCredential _facebookCredential(AccessToken accessToken) {
    authLog(
      'facebook:buildCredential',
      'type=${accessToken.type} token=${authTokenSummary(accessToken.tokenString)}',
    );

    if (accessToken is LimitedToken) {
      final nonce = accessToken.nonce.trim();
      if (nonce.isEmpty) {
        throw ApiException('Facebook sign-in failed: missing login nonce.');
      }
      authLog('facebook:buildCredential', 'using LimitedToken + nonce');
      return OAuthProvider('facebook.com').credential(
        idToken: accessToken.tokenString,
        rawNonce: nonce,
      );
    }

    authLog('facebook:buildCredential', 'using FacebookAuthProvider access token');
    return FacebookAuthProvider.credential(accessToken.tokenString);
  }

  Future<AppUser> loginWithFacebook() async {
    authLog('facebook:loginWithFacebook:start');
    final result = await _requestFacebookLogin();

    if (result.status == LoginStatus.cancelled) {
      authLog('facebook:loginWithFacebook:throwCancelled');
      throw AuthCancelledException();
    }
    if (result.status != LoginStatus.success) {
      authLog('facebook:loginWithFacebook:failed', result.message);
      throw ApiException(result.message ?? 'Facebook sign-in failed.');
    }

    final accessToken = result.accessToken;
    if (accessToken == null) {
      authLog('facebook:loginWithFacebook:noAccessToken');
      throw ApiException('Facebook sign-in failed: no access token.');
    }

    // Fetch Facebook profile immediately while the SDK session is active.
    final facebookProfile = await fetchFacebookProfile(accessToken);
    authLog(
      'facebook:profile',
      'name=${facebookProfile?.name} email=${facebookProfile?.email} picture=${facebookProfile?.pictureUrl != null}',
    );

    final credential = _facebookCredential(accessToken);

    authLog('facebook:firebaseSignIn:start');
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    User firebaseUser = userCredential.user!;
    authLog(
      'facebook:firebaseSignIn:success',
      'uid=${firebaseUser.uid} email=${firebaseUser.email} providers=${firebaseUser.providerData.map((p) => p.providerId).join(",")}',
    );

    final facebookName = facebookProfile?.name?.trim();
    if (facebookName != null &&
        facebookName.isNotEmpty &&
        (firebaseUser.displayName == null ||
            firebaseUser.displayName!.trim().isEmpty)) {
      try {
        await firebaseUser.updateDisplayName(facebookName);
        authLog('facebook:updateDisplayName', facebookName);
      } catch (e) {
        authLog('facebook:updateDisplayName:error', e);
      }
    }

    final pictureUrl = facebookProfile?.pictureUrl;
    if (pictureUrl != null) {
      try {
        await firebaseUser.updatePhotoURL(pictureUrl);
        await firebaseUser.reload();
        firebaseUser = _firebaseAuth.currentUser ?? firebaseUser;
        authLog('facebook:updatePhotoURL', 'ok');
      } catch (e) {
        authLog('facebook:updatePhotoURL:error', e);
      }
    }

    await _persistUser(
      firebaseUser,
      imageUrl: pictureUrl ?? resolveUserPhotoUrl(firebaseUser),
      name: facebookName,
    );

    final appUser = _mapUser(
      firebaseUser,
      imageUrl: pictureUrl ?? resolveUserPhotoUrl(firebaseUser),
      name: facebookName,
    );
    authLog(
      'facebook:loginWithFacebook:done',
      'uid=${appUser.id} name=${appUser.name}',
    );
    return appUser;
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
    await _googleSignIn.signOut();
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
