import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/core/config/app_config.dart';
import 'package:beltei_app/data/repositories/notifications_repository.dart';
import 'package:beltei_app/screens/browse_screen.dart';
import 'package:beltei_app/screens/dashboard_screen.dart';
import 'package:beltei_app/screens/my_claims_screen.dart';
import 'package:beltei_app/screens/my_items_screen.dart';
import 'package:beltei_app/screens/notifications_screen.dart';
import 'package:beltei_app/screens/profile_screen.dart';
import 'package:beltei_app/screens/settings_screen.dart';
import 'package:beltei_app/screens/report_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _refreshUnread();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeIfNeeded());
  }

  void _showWelcomeIfNeeded() {
    final auth = Get.find<AuthController>();
    final label = auth.takeWelcomeMessage();
    if (!mounted || label == null || label.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('សូមស្វាគមន៍ — $label')),
    );
  }

  Future<void> _logout() async {
    final auth = Get.find<AuthController>();
    final name = auth.user.value?.displayName ?? 'User';
    await auth.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signed out — $name')),
    );
    setState(() => _index = 4);
  }

  Future<void> _refreshUnread() async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn) return;
    try {
      final repo = Get.find<NotificationsRepository>();
      final result = await repo.fetch(limit: 1);
      if (mounted) setState(() => _unreadNotifications = result.unreadCount);
    } catch (_) {}
  }

  void _openReport() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search_off),
              title: const Text('Report lost'),
              onTap: () {
                Navigator.pop(ctx);
                Get.to(() => const ReportItemScreen(initialType: 'LOST'))
                    ?.then((_) => _refreshUnread());
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Report found'),
              onTap: () {
                Navigator.pop(ctx);
                Get.to(() => const ReportItemScreen(initialType: 'FOUND'))
                    ?.then((_) => _refreshUnread());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Obx(() {
            final auth = Get.find<AuthController>();
            if (!auth.isLoggedIn) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'my_items':
                    Get.to(() => const MyItemsScreen());
                  case 'my_claims':
                    Get.to(() => const MyClaimsScreen());
                  case 'settings':
                    Get.to(() => const SettingsScreen());
                  case 'logout':
                    _logout();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'my_items', child: Text('My items')),
                PopupMenuItem(value: 'my_claims', child: Text('My claims')),
                PopupMenuItem(value: 'settings', child: Text('Settings')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'logout', child: Text('Sign out')),
              ],
            );
          }),
        ],
        title: Obx(() {
          final auth = Get.find<AuthController>();
          final userLabel =
              auth.isLoggedIn ? auth.user.value?.displayName : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfig.universityLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
              ),
              Text(
                AppConfig.appName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white),
              ),
              if (userLabel != null && userLabel.isNotEmpty)
                Text(
                  userLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
            ],
          );
        }),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          BrowseScreen(),
          NotificationsScreen(),
          SizedBox.shrink(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openReport,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 3) {
            _openReport();
            return;
          }
          setState(() => _index = i);
          if (i == 2) _refreshUnread();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text('$_unreadNotifications'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Report',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
