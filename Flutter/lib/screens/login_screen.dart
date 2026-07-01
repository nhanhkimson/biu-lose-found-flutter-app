import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/core/utils/validators.dart';
import 'package:beltei_app/screens/app_shell.dart';
import 'package:beltei_app/screens/register_screen.dart';
import 'package:beltei_app/widgets/app_logo.dart';
import 'package:beltei_app/widgets/auth_text_field.dart';
import 'package:beltei_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = Get.find<AuthController>();
    final ok = await auth.login(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      Get.offAll(() => const AppShell());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error.value)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        isValidEmail(_email.text) && _password.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const AppLogo(size: 90),
              const SizedBox(height: 24),
              AuthTextField(
                hintText: 'អ៊ីមែល',
                controller: _email,
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                suffixIcon: _emailIcon(_email.text),
              ),
              const SizedBox(height: 14),
              AuthTextField(
                hintText: 'លេខសម្ងាត់',
                controller: _password,
                prefixIcon: Icons.lock_outline,
                obscureText: _hidePassword,
                onChanged: (_) => setState(() {}),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              const SizedBox(height: 18),
              Obx(() {
                final auth = Get.find<AuthController>();
                return PrimaryButton(
                  label: 'ចូលប្រព័ន្ធ',
                  loading: auth.isLoading.value,
                  onPressed: canSubmit ? _submit : null,
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ឬ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() {
                final auth = Get.find<AuthController>();
                return OutlinedButton.icon(
                  onPressed: auth.isLoading.value
                      ? null
                      : () async {
                          final ok = await auth.loginWithFacebook();
                          if (!mounted) return;
                          if (ok) {
                            Get.offAll(() => const AppShell());
                            return;
                          }
                          if (auth.error.value.isEmpty) return;
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(auth.error.value)),
                          );
                        },
                  icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                  label: const Text('ចូលជាមួយ Facebook'),
                );
              }),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('មិនមានគណនីទេ?', style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => Get.to(() => const RegisterScreen()),
                    child: const Text('ចុះឈ្មោះ'),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Get.off(() => const AppShell()),
                child: const Text('Browse without signing in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _emailIcon(String value) {
    if (value.trim().isEmpty) return null;
    final ok = isValidEmail(value);
    return Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.green : Colors.red);
  }
}
