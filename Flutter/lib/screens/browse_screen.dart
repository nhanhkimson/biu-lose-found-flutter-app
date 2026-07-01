import 'package:beltei_app/core/theme/app_colors.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:beltei_app/data/repositories/items_repository.dart';
import 'package:beltei_app/screens/item_detail_screen.dart';
import 'package:beltei_app/widgets/browse_filters_sheet.dart';
import 'package:beltei_app/widgets/empty_state.dart';
import 'package:beltei_app/widgets/item_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _repo = Get.find<ItemsRepository>();
  final _search = TextEditingController();

  List<LostFoundItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  String? _filterType;
  BrowseFilters _filters = const BrowseFilters();
  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      if (_page >= _totalPages || _loadingMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final result = await _repo.fetchItems(
        page: refresh ? 1 : _page + 1,
        type: _filterType,
        q: _search.text.trim().isEmpty ? null : _search.text.trim(),
        category: _filters.category,
        building: _filters.building,
        status: _filters.status,
        dateFrom: _filters.dateFrom?.toIso8601String().split('T').first,
        dateTo: _filters.dateTo?.toIso8601String().split('T').first,
        preferCache: refresh,
      );
      setState(() {
        if (refresh) {
          _items = result.items;
          _page = result.page;
        } else {
          _items = [..._items, ...result.items];
          _page = result.page;
        }
        _totalPages = result.totalPages;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _setType(String? type) {
    if (_filterType == type) return;
    setState(() => _filterType = type);
    _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search items…',
                    prefixIcon: Icon(Icons.search, color: primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        _load(refresh: true);
                      },
                    ),
                  ),
                  onSubmitted: (_) => _load(refresh: true),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: _filters.hasActive,
                smallSize: 8,
                child: IconButton(
                  onPressed: () async {
                    final next = await showBrowseFiltersSheet(
                      context,
                      initial: _filters,
                    );
                    if (next == null) return;
                    setState(() => _filters = next);
                    _load(refresh: true);
                  },
                  icon: const Icon(Icons.tune),
                  tooltip: 'Filters',
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _typeChip('All', null),
              const SizedBox(width: 8),
              _typeChip('Lost', 'LOST', AppColors.lost),
              const SizedBox(width: 8),
              _typeChip('Found', 'FOUND', AppColors.found),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _body(primary)),
      ],
    );
  }

  Widget _typeChip(String label, String? value, [Color? color]) {
    final selected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setType(value),
      selectedColor: (color ?? Theme.of(context).colorScheme.primary)
          .withValues(alpha: 0.2),
    );
  }

  Widget _body(Color primary) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text('Could not load items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => _load(refresh: true), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const EmptyState(
        title: 'No items found',
        subtitle: 'Try another search or filter',
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: primary)),
            );
          }
          final item = _items[index];
          if (index == _items.length - 1 && !_loadingMore && _page < _totalPages) {
            _load();
          }
          return ItemCard(
            item: item,
            onTap: () => Get.to(() => ItemDetailScreen(itemId: item.id)),
          );
        },
      ),
    );
  }
}
