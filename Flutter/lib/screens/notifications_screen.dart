import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:beltei_app/data/repositories/notifications_repository.dart';
import 'package:beltei_app/core/utils/notification_navigation.dart';
import 'package:beltei_app/screens/login_screen.dart';
import 'package:beltei_app/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = Get.find<NotificationsRepository>();
  List<AppNotification> _items = [];
  int _unread = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn) {
      setState(() {
        _loading = false;
        _items = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.fetch(limit: 50);
      setState(() {
        _items = result.notifications;
        _unread = result.unreadCount;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAll() async {
    await _repo.markAllRead();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyState(
              title: 'Sign in for notifications',
              subtitle: 'Campus updates appear here after you log in',
              icon: Icons.notifications_none,
            ),
            FilledButton(
              onPressed: () => Get.to(() => const LoginScreen()),
              child: const Text('Sign in'),
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          if (_unread > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _markAll, child: const Text('Mark all read')),
                ),
              ),
            ),
          if (_items.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                title: 'No notifications yet',
                icon: Icons.notifications_none,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final n = _items[index];
                  return ListTile(
                    onTap: () async {
                      if (!n.read) {
                        await _repo.markRead([n.id]);
                      }
                      openNotificationLink(n.link);
                      await _load();
                    },
                    leading: CircleAvatar(
                      backgroundColor: n.read
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      child: Icon(
                        n.read ? Icons.notifications_none : Icons.notifications_active,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      DateFormat.MMMd().format(n.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
                childCount: _items.length,
              ),
            ),
        ],
      ),
    );
  }
}
