import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/core/config/app_config.dart';
import 'package:beltei_app/screens/app_shell.dart';
import 'package:beltei_app/screens/login_screen.dart';
import 'package:beltei_app/widgets/app_logo.dart';
import 'package:beltei_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Get.find<AuthController>();
      if (auth.isLoggedIn) {
        Get.off(() => const AppShell());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const AppLogo(size: 110),
              const SizedBox(height: 20),
              Text(
                AppConfig.universityLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Report and find campus belongings',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'ចាប់ផ្តើម',
                onPressed: () {
                  final auth = Get.find<AuthController>();
                  if (auth.isLoggedIn) {
                    Get.off(() => const AppShell());
                  } else {
                    Get.off(() => const LoginScreen());
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Get.off(() => const AppShell()),
                child: const Text('Browse as guest'),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
