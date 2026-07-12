import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/core/constants/lost_found_constants.dart';
import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/core/utils/date_format.dart';
import 'package:beltei_app/core/utils/firebase_firestore_errors.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:beltei_app/data/repositories/items_repository.dart';
import 'package:beltei_app/screens/claim_screen.dart';
import 'package:beltei_app/widgets/item_card.dart';
import 'package:beltei_app/widgets/app_image.dart';
import 'package:beltei_app/widgets/type_badge.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    super.key,
    required this.itemId,
    this.ownerActions = false,
  });

  final String itemId;
  final bool ownerActions;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _repo = Get.find<ItemsRepository>();
  LostFoundItem? _item;
  List<LostFoundItem> _similar = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repo.fetchDetail(widget.itemId);
      List<LostFoundItem> similar = const [];
      try {
        similar = await _repo.fetchSimilar(widget.itemId);
      } catch (_) {}
      setState(() {
        _item = detail;
        _similar = similar;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException
            ? e.message
            : e is FirebaseException
                ? mapFirestoreError(e)
                : 'Could not load item details.';
        _loading = false;
      });
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _loading = true);
    try {
      final updated = await _repo.updateStatus(widget.itemId, status);
      setState(() {
        _item = updated;
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _openClaim() {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to submit a claim')),
      );
      return;
    }
    final item = _item;
    if (item == null) return;
    Get.to(() => ClaimScreen(item: item));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(context, _item!),
      bottomNavigationBar: _item == null ? null : _buildBottomBar(_item!),
    );
  }

  Widget? _buildBottomBar(LostFoundItem item) {
    if (widget.ownerActions) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (item.status == 'OPEN')
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => _setStatus('RESOLVED'),
                    child: const Text('Mark resolved'),
                  ),
                ),
              if (item.status == 'OPEN') const SizedBox(width: 8),
              if (item.status != 'CLOSED')
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : () => _setStatus('CLOSED'),
                    child: const Text('Close listing'),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    if (item.status != 'OPEN') return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _openClaim,
          icon: const Icon(Icons.handshake_outlined),
          label: Text(item.isLost ? 'I found this' : "It's mine"),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LostFoundItem item) {
    final gallery = item.gallery;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (gallery.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: gallery.length,
                itemBuilder: (_, i) => AppImage(
                  url: gallery[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Colors.black12,
                    child: Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TypeBadge(type: item.type),
                    const SizedBox(width: 8),
                    if (item.status != null)
                      Chip(
                        label: Text(
                          LostFoundConstants.statusLabel[item.status] ?? item.status!,
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  formatEventDate(item.eventDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (item.description != null) ...[
                  Text('Description', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(item.description!),
                  const SizedBox(height: 16),
                ],
                _infoRow(Icons.place_outlined, '${item.building}${item.roomHint != null ? ' · ${item.roomHint}' : ''}'),
                _infoRow(
                  Icons.category_outlined,
                  LostFoundConstants.categoryLabel[item.category] ?? item.category,
                ),
                if (item.color != null && item.color!.isNotEmpty)
                  _infoRow(Icons.palette_outlined, item.color!),
                if (item.brand != null && item.brand!.isNotEmpty)
                  _infoRow(Icons.label_outline, item.brand!),
                if (item.timeApprox != null && item.timeApprox!.isNotEmpty)
                  _infoRow(Icons.schedule, item.timeApprox!),
                if (item.foundDisposition != null)
                  _infoRow(
                    Icons.inventory_2_outlined,
                    LostFoundConstants.foundDispositionLabel[item.foundDisposition] ??
                        item.foundDisposition!,
                  ),
                if (item.reward != null && item.reward!.isNotEmpty)
                  _infoRow(Icons.card_giftcard, item.reward!),
                if (item.viewCount != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${item.viewCount} views', style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          if (_similar.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Similar items', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            ..._similar.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ItemCard(
                  item: s,
                  onTap: () => Get.to(() => ItemDetailScreen(itemId: s.id)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
