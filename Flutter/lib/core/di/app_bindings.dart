import 'package:beltei_app/core/network/api_client.dart';
import 'package:beltei_app/core/storage/session_store.dart';
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
    Get.put(
      AuthRepository(session),
      permanent: true,
    );
    Get.put(
      ItemsRepository(Get.find<ApiClient>(), Get.find<ItemsCache>()),
      permanent: true,
    );
    Get.put(ClaimsRepository(Get.find<ApiClient>()), permanent: true);
    Get.put(
      DashboardRepository(
        Get.find<ApiClient>(),
        Get.find<ItemsRepository>(),
        Get.find<ClaimsRepository>(),
      ),
      permanent: true,
    );
    Get.put(
      NotificationsRepository(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put(
      ProfileRepository(
        session,
        Get.find<ItemsRepository>(),
        Get.find<ClaimsRepository>(),
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
