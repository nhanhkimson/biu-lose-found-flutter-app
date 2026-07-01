import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:beltei_app/data/repositories/items_repository.dart';
import 'package:beltei_app/screens/item_detail_screen.dart';
import 'package:beltei_app/screens/login_screen.dart';
import 'package:beltei_app/widgets/empty_state.dart';
import 'package:beltei_app/widgets/item_card.dart';
import 'package:beltei_app/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({
    super.key,
    this.initialType,
    this.initialStatus,
  });

  final String? initialType;
  final String? initialStatus;

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  final _repo = Get.find<ItemsRepository>();
  List<LostFoundItem> _items = [];
  bool _loading = true;
  String? _error;
  String? _filterType;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _filterType = widget.initialType;
    _filterStatus = widget.initialStatus;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repo.fetchMyItems(
        type: _filterType,
        status: _filterStatus,
      );
      setState(() {
        _items = page.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('My items')),
        body: Center(
          child: FilledButton(
            onPressed: () => Get.to(() => const LoginScreen()),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My items')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All types'),
                  selected: _filterType == null,
                  onSelected: (_) {
                    setState(() => _filterType = null);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Lost'),
                  selected: _filterType == 'LOST',
                  onSelected: (_) {
                    setState(() => _filterType = 'LOST');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Found'),
                  selected: _filterType == 'FOUND',
                  onSelected: (_) {
                    setState(() => _filterType = 'FOUND');
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const EmptyState(
        title: 'No listings yet',
        subtitle: 'Report a lost or found item to get started',
        icon: Icons.inventory_2_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Stack(
            children: [
              ItemCard(
                item: item,
                onTap: () => Get.to(
                  () => ItemDetailScreen(
                    itemId: item.id,
                    ownerActions: true,
                  ),
                ),
              ),
              if (item.status != null)
                Positioned(
                  top: 12,
                  right: 20,
                  child: StatusBadge(status: item.status!),
                ),
            ],
          );
        },
      ),
    );
  }
}
