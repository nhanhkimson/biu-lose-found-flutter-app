import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/data/models/claim_item.dart';
import 'package:beltei_app/data/repositories/claims_repository.dart';
import 'package:beltei_app/screens/item_detail_screen.dart';
import 'package:beltei_app/screens/login_screen.dart';
import 'package:beltei_app/widgets/status_badge.dart';
import 'package:beltei_app/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  final _repo = Get.find<ClaimsRepository>();
  List<ClaimItem> _claims = [];
  bool _loading = true;
  String? _error;
  String? _filterStatus;

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
      final page = await _repo.fetchMyClaims(status: _filterStatus);
      setState(() {
        _claims = page.claims;
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
        appBar: AppBar(title: const Text('My claims')),
        body: Center(
          child: FilledButton(
            onPressed: () => Get.to(() => const LoginScreen()),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My claims')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final status in [null, 'PENDING', 'APPROVED', 'REJECTED'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status ?? 'All'),
                      selected: _filterStatus == status,
                      onSelected: (_) {
                        setState(() => _filterStatus = status);
                        _load();
                      },
                    ),
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
    if (_claims.isEmpty) {
      return const EmptyState(
        title: 'No claims yet',
        subtitle: 'Submit a claim from an item listing',
        icon: Icons.fact_check_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _claims.length,
        itemBuilder: (context, index) {
          final claim = _claims[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(claim.itemTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  ClaimStatusBadge(status: claim.status),
                  const SizedBox(height: 6),
                  Text(
                    claim.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (claim.adminNote != null && claim.adminNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Note: ${claim.adminNote}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                ],
              ),
              trailing: Text(
                DateFormat.MMMd().format(claim.createdAt.toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              isThreeLine: true,
              onTap: () => Get.to(() => ItemDetailScreen(itemId: claim.itemId)),
            ),
          );
        },
      ),
    );
  }
}
