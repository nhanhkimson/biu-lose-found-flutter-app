import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/core/utils/auth_debug_log.dart';
import 'package:beltei_app/core/utils/firebase_auth_errors.dart';
import 'package:beltei_app/core/utils/firebase_firestore_errors.dart';
import 'package:beltei_app/data/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:beltei_app/data/repositories/auth_repository.dart';
import 'package:beltei_app/controllers/profile_controller.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  AuthController(this._auth);

  final AuthRepository _auth;

  final Rxn<AppUser> user = Rxn<AppUser>();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  String? _welcomeMessage;

  bool get isLoggedIn => user.value != null;

  void setWelcomeMessage(String message) {
    final trimmed = message.trim();
    _welcomeMessage = trimmed.isEmpty ? null : trimmed;
  }

  /// One-time welcome text shown after login/register navigation.
  String? takeWelcomeMessage() {
    final message = _welcomeMessage;
    _welcomeMessage = null;
    return message;
  }

  late final Future<void> _restoreFuture;

  @override
  void onInit() {
    super.onInit();
    _restoreFuture = _restore();
  }

  /// Await before routing on cold start so SharedPreferences session is applied.
  Future<void> waitForRestore() => _restoreFuture;

  Future<void> _restore() async {
    authLog('restore:start');
    if (!await _auth.isLoggedIn()) {
      authLog('restore:skip', 'not logged in');
      return;
    }

    user.value = await _auth.currentUser();
    authLog('restore:cachedUser', user.value?.id);
    isLoading.value = true;
    try {
      final remote = await _auth.fetchSessionUser();
      if (remote != null) user.value = remote;
      authLog('restore:remoteUser', remote?.id);
      if (Get.isRegistered<ProfileController>() && user.value != null) {
        Get.find<ProfileController>().profile.value = user.value;
      }
    } finally {
      isLoading.value = false;
      authLog('restore:done', 'isLoggedIn=$isLoggedIn');
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    error.value = '';
    try {
      user.value = await _auth.login(email: email, password: password);
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().profile.value = user.value;
      }
      setWelcomeMessage(user.value?.displayName ?? '');
      return true;
    } on FirebaseAuthException catch (e) {
      error.value = mapFirebaseAuthError(e);
      return false;
    } on ApiException catch (e) {
      error.value = e.message;
      return false;
    } on FirebaseException catch (e) {
      error.value = mapFirestoreError(e);
      return false;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loginWithGoogle() async {
    authLog('controller:googleLogin:start');
    isLoading.value = true;
    error.value = '';
    try {
      user.value = await _auth.loginWithGoogle();
      authLog(
        'controller:googleLogin:success',
        'uid=${user.value?.id} name=${user.value?.name}',
      );
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().profile.value = user.value;
      }
      setWelcomeMessage(user.value?.displayName ?? '');
      return true;
    } on AuthCancelledException {
      authLog('controller:googleLogin:cancelled');
      return false;
    } on FirebaseAuthException catch (e) {
      error.value = mapFirebaseAuthError(e);
      authLog('controller:googleLogin:firebaseAuthError', '${e.code}: ${e.message}');
      return false;
    } on ApiException catch (e) {
      error.value = e.message;
      authLog('controller:googleLogin:apiException', e.message);
      return false;
    } on FirebaseException catch (e) {
      error.value = mapFirestoreError(e);
      authLog('controller:googleLogin:firebaseException', '${e.code}: ${e.message}');
      return false;
    } catch (e, st) {
      error.value = e.toString();
      authLog('controller:googleLogin:unknownError', e);
      authLog('controller:googleLogin:stack', st);
      return false;
    } finally {
      isLoading.value = false;
      authLog(
        'controller:googleLogin:done',
        'ok=${user.value != null} error="${error.value}" isLoggedIn=$isLoggedIn',
      );
    }
  }

  Future<bool> loginWithFacebook() async {
    authLog('controller:facebookLogin:start');
    isLoading.value = true;
    error.value = '';
    try {
      user.value = await _auth.loginWithFacebook();
      authLog(
        'controller:facebookLogin:success',
        'uid=${user.value?.id} name=${user.value?.name}',
      );
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().profile.value = user.value;
      }
      setWelcomeMessage(user.value?.displayName ?? '');
      return true;
    } on AuthCancelledException {
      authLog('controller:facebookLogin:cancelled');
      return false;
    } on FirebaseAuthException catch (e) {
      error.value = mapFirebaseAuthError(e);
      authLog('controller:facebookLogin:firebaseAuthError', '${e.code}: ${e.message}');
      return false;
    } on ApiException catch (e) {
      error.value = e.message;
      authLog('controller:facebookLogin:apiException', e.message);
      return false;
    } on FirebaseException catch (e) {
      error.value = mapFirestoreError(e);
      authLog('controller:facebookLogin:firebaseException', '${e.code}: ${e.message}');
      return false;
    } catch (e, st) {
      error.value = e.toString();
      authLog('controller:facebookLogin:unknownError', e);
      authLog('controller:facebookLogin:stack', st);
      return false;
    } finally {
      isLoading.value = false;
      authLog(
        'controller:facebookLogin:done',
        'ok=${user.value != null} error="${error.value}" isLoggedIn=$isLoggedIn',
      );
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? studentId,
  }) async {
    isLoading.value = true;
    error.value = '';
    try {
      user.value = await _auth.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        studentId: studentId,
      );
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().profile.value = user.value;
      }
      setWelcomeMessage(user.value?.displayName ?? '');
      return true;
    } on FirebaseAuthException catch (e) {
      error.value = mapFirebaseAuthError(e);
      return false;
    } on ApiException catch (e) {
      error.value = e.message;
      return false;
    } on FirebaseException catch (e) {
      error.value = mapFirestoreError(e);
      return false;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    authLog('controller:logout');
    await _auth.logout();
    user.value = null;
  }

  Future<void> refreshSessionUser() async {
    if (!isLoggedIn) return;
    final remote = await _auth.fetchSessionUser();
    if (remote != null) user.value = remote;
  }
}
