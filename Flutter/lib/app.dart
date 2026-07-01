import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/controllers/theme_controller.dart';
import 'package:beltei_app/core/config/app_config.dart';
import 'package:beltei_app/core/di/app_bindings.dart';
import 'package:beltei_app/core/storage/session_store.dart';
import 'package:beltei_app/core/theme/app_theme.dart';
import 'package:beltei_app/data/repositories/auth_repository.dart';
import 'package:beltei_app/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoseFoundApp extends StatelessWidget {
  const LoseFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConfig.appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: theme.mode.value,
        home: const SplashScreen(),
      ),
    );
  }
}

Future<void> bootstrapApp() async {
  AppBindings().dependencies();
  final auth = Get.put(
    AuthController(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put(ThemeController(Get.find<SessionStore>()), permanent: true);
  await auth.waitForRestore();
}
