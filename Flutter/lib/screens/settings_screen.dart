import 'package:beltei_app/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(
        () => ListView(
          children: [
            const ListTile(
              title: Text('Appearance'),
              subtitle: Text('Matches the web app theme switcher'),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: theme.mode.value,
              onChanged: (v) {
                if (v != null) theme.setMode(v);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: theme.mode.value,
              onChanged: (v) {
                if (v != null) theme.setMode(v);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: theme.mode.value,
              onChanged: (v) {
                if (v != null) theme.setMode(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
