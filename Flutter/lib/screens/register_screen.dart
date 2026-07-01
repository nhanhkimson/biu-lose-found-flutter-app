import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/core/utils/validators.dart';
import 'package:beltei_app/screens/app_shell.dart';
import 'package:beltei_app/widgets/app_logo.dart';
import 'package:beltei_app/widgets/auth_text_field.dart';
import 'package:beltei_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _studentId = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _studentId.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = Get.find<AuthController>();
    final ok = await auth.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      confirmPassword: _confirm.text,
      studentId: _studentId.text,
    );
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
    final canSubmit = _name.text.trim().length >= 2 &&
        isValidEmail(_email.text) &&
        _password.text.length >= 8 &&
        _password.text == _confirm.text;

    return Scaffold(
      appBar: AppBar(title: const Text('ចុះឈ្មោះ')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const AppLogo(size: 72),
              const SizedBox(height: 20),
              AuthTextField(
                hintText: 'ឈ្មោះ',
                controller: _name,
                prefixIcon: Icons.person_outline,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                hintText: 'អ៊ីមែល',
                controller: _email,
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                hintText: 'លេខសិស្ស (ជម្រើស)',
                controller: _studentId,
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                hintText: 'លេខសម្ងាត់',
                controller: _password,
                prefixIcon: Icons.lock_outline,
                obscureText: _hide,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                hintText: 'បញ្ជាក់លេខសម្ងាត់',
                controller: _confirm,
                prefixIcon: Icons.lock_outline,
                obscureText: _hide,
                onChanged: (_) => setState(() {}),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hide = !_hide),
                  icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                final auth = Get.find<AuthController>();
                return PrimaryButton(
                  label: 'ចុះឈ្មោះ',
                  loading: auth.isLoading.value,
                  onPressed: canSubmit ? _submit : null,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
