import 'package:beltei_app/core/network/api_client.dart';
import 'package:beltei_app/core/storage/session_store.dart';
import 'package:beltei_app/data/firebase/claims_store.dart';
import 'package:beltei_app/data/firebase/items_store.dart';
import 'package:beltei_app/data/firebase/notifications_store.dart';
import 'package:beltei_app/data/firebase/storage_upload_store.dart';
import 'package:beltei_app/data/firebase/user_profile_store.dart';
import 'package:beltei_app/data/local/items_cache.dart';
import 'package:beltei_app/data/repositories/auth_repository.dart';
import 'package:beltei_app/data/repositories/claims_repository.dart';
import 'package:beltei_app/data/repositories/dashboard_repository.dart';
import 'package:beltei_app/data/repositories/items_repository.dart';
import 'package:beltei_app/data/repositories/notifications_repository.dart';
import 'package:beltei_app/controllers/profile_controller.dart';
import 'package:beltei_app/data/repositories/profile_repository.dart';
import 'package:get/get.dart';

/// Registers app-wide dependencies (GetX).
class AppBindings extends Bindings {
  @override
  void dependencies() {
    final session = SessionStore();
    Get.put(session, permanent: true);
    Get.put(ApiClient(session), permanent: true);
    Get.put(ItemsCache(), permanent: true);

    Get.put(ItemsStore(), permanent: true);
    Get.put(ClaimsStore(), permanent: true);
    Get.put(NotificationsStore(), permanent: true);
    Get.put(
      StorageUploadStore(apiClient: Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put(UserProfileStore(), permanent: true);

    Get.put(
      AuthRepository(session, profileStore: Get.find<UserProfileStore>()),
      permanent: true,
    );
    Get.put(
      ItemsRepository(Get.find<ItemsStore>(), Get.find<ItemsCache>()),
      permanent: true,
    );
    Get.put(
      ClaimsRepository(
        Get.find<ClaimsStore>(),
        Get.find<ItemsStore>(),
        Get.find<NotificationsStore>(),
      ),
      permanent: true,
    );
    Get.put(
      DashboardRepository(
        Get.find<ItemsRepository>(),
        Get.find<ClaimsRepository>(),
      ),
      permanent: true,
    );
    Get.put(
      NotificationsRepository(Get.find<NotificationsStore>()),
      permanent: true,
    );
    Get.put(
      ProfileRepository(
        session,
        Get.find<ItemsRepository>(),
        Get.find<ClaimsRepository>(),
        profileStore: Get.find<UserProfileStore>(),
        storage: Get.find<StorageUploadStore>(),
      ),
      permanent: true,
    );
    Get.put(
      ProfileController(
        Get.find<ProfileRepository>(),
        Get.find<AuthRepository>(),
      ),
      permanent: true,
    );
  }
}
