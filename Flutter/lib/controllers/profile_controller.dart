import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/core/utils/firebase_firestore_errors.dart';
import 'package:beltei_app/data/models/app_user.dart';
import 'package:beltei_app/data/repositories/auth_repository.dart';
import 'package:beltei_app/data/repositories/profile_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  ProfileController(this._profile, this._auth);

  final ProfileRepository _profile;
  final AuthRepository _auth;

  final Rxn<AppUser> profile = Rxn<AppUser>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<AuthController>()) {
      final u = Get.find<AuthController>().user.value;
      if (u != null) profile.value = u;
    }
  }

  Future<bool> ensureLoaded() async {
    if (!await _auth.isLoggedIn()) {
      profile.value = null;
      return false;
    }
    if (profile.value?.recentActivity.isNotEmpty == true ||
        (profile.value?.stats != null && profile.value!.recentActivity.isEmpty)) {
      if (profile.value?.stats != null) return true;
    }
    return load(force: true);
  }

  Future<bool> load({bool force = false}) async {
    if (!await _auth.isLoggedIn()) {
      profile.value = null;
      return false;
    }
    if (!force && profile.value?.stats != null) return true;

    isLoading.value = true;
    error.value = '';
    try {
      final user = await _profile.fetchProfile();
      profile.value = user;
      _syncAuth(user);
      return true;
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

  Future<bool> saveProfile({
    required String name,
    String? studentId,
    String? imageUrl,
  }) async {
    isSaving.value = true;
    error.value = '';
    try {
      final user = await _profile.updateProfile(
        name: name,
        studentId: studentId,
        imageUrl: imageUrl,
      );
      profile.value = user;
      _syncAuth(user);
      return true;
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
      isSaving.value = false;
    }
  }

  Future<String?> uploadAvatarFile(XFile file) async {
    isSaving.value = true;
    error.value = '';
    try {
      return await _profile.uploadAvatarFile(file);
    } on ApiException catch (e) {
      error.value = e.message;
      return null;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      error.value = 'Passwords do not match';
      return false;
    }
    if (newPassword.length < 8) {
      error.value = 'New password must be at least 8 characters';
      return false;
    }

    isSaving.value = true;
    error.value = '';
    try {
      await _profile.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
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
      isSaving.value = false;
    }
  }

  void _syncAuth(AppUser user) {
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().user.value = user;
    }
  }
}
