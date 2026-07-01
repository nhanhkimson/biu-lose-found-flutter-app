import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/core/constants/lost_found_constants.dart';
import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/core/theme/app_colors.dart';
import 'package:beltei_app/data/models/app_user.dart';
import 'package:beltei_app/data/models/dashboard_data.dart';
import 'package:beltei_app/data/repositories/dashboard_repository.dart';
import 'package:beltei_app/screens/item_detail_screen.dart';
import 'package:beltei_app/screens/login_screen.dart';
import 'package:beltei_app/screens/my_claims_screen.dart';
import 'package:beltei_app/screens/my_items_screen.dart';
import 'package:beltei_app/widgets/empty_state.dart';
import 'package:beltei_app/widgets/profile_stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = Get.find<DashboardRepository>();
  DashboardPayload? _data;
  bool _loading = true;
  String? _error;
  Worker? _authWorker;

  @override
  void initState() {
    super.initState();
    _load();
    final auth = Get.find<AuthController>();
    _authWorker = ever(auth.user, (_) => _load());
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn) {
      if (mounted) {
        setState(() {
          _loading = false;
          _data = null;
          _error = null;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _repo.fetch();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load dashboard. Pull down to retry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      if (!auth.isLoggedIn) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyState(
                title: 'Sign in for your dashboard',
                subtitle: 'Stats, matches, and activity appear here',
                icon: Icons.dashboard_outlined,
              ),
              FilledButton(
                onPressed: () => Get.to(() => const LoginScreen()),
                child: const Text('Sign in'),
              ),
            ],
          ),
        );
      }

      if (_loading) return const Center(child: CircularProgressIndicator());
      if (_error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        );
      }

      final data = _data!;
      final user = auth.user.value;

      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null) ...[
              _WelcomeHeader(user: user),
              const SizedBox(height: 20),
            ],
            Text('Overview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ProfileStatsGrid(
              stats: ProfileStats(
                myLost: data.stats.myLost,
                myFound: data.stats.myFound,
                myClaims: data.stats.myClaims,
                myResolved: data.stats.myResolved,
              ),
              onLostTap: () => Get.to(() => const MyItemsScreen(initialType: 'LOST')),
              onFoundTap: () => Get.to(() => const MyItemsScreen(initialType: 'FOUND')),
              onClaimsTap: () => Get.to(() => const MyClaimsScreen()),
              onResolvedTap: () => Get.to(
                () => const MyItemsScreen(initialStatus: 'RESOLVED'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Possible matches', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (data.matches.isNotEmpty)
                  Text(
                    '${data.matches.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (data.matches.isEmpty)
              const Text('No match suggestions right now. Keep listings open and detailed.')
            else
              ...data.matches.map((m) => _MatchCard(match: m)),
            const SizedBox(height: 24),
            Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data.activity.isEmpty)
              const Text('No recent activity yet.')
            else
              ...data.activity.map((row) => _ActivityTile(row: row)),
          ],
        ),
      );
    });
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.image?.trim() ?? '';
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.surfaceMutedLight,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                user.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchSuggestion match;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(match.otherTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          'Your ${match.mySide.toLowerCase()}: ${match.myItemTitle}\n'
          '${match.confidence}% match · ${match.building}',
          maxLines: 3,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TypeChipLabel(type: match.otherSide),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        isThreeLine: true,
        onTap: () => Get.to(() => ItemDetailScreen(itemId: match.otherItemId)),
      ),
    );
  }
}

class TypeChipLabel extends StatelessWidget {
  const TypeChipLabel({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isLost = type == 'LOST';
    return Text(
      LostFoundConstants.typeLabel[type] ?? type,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isLost ? AppColors.lost : AppColors.found,
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final kind = row['kind'] as String? ?? 'item';
    final at = DateTime.tryParse(row['at'] as String? ?? '');
    final itemId = row['itemId'] as String?;

    String title;
    String subtitle;
    if (kind == 'claim') {
      title = row['itemTitle'] as String? ?? 'Claim';
      final status = row['claimStatus'] as String? ?? '';
      subtitle = 'Claim · $status';
    } else {
      title = row['title'] as String? ?? 'Item';
      final status = row['status'] as String? ?? '';
      final type = row['type'] as String? ?? '';
      subtitle = '${LostFoundConstants.typeLabel[type] ?? type} · $status';
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
      trailing: at != null
          ? Text(
              DateFormat.MMMd().format(at.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: itemId != null
          ? () => Get.to(() => ItemDetailScreen(itemId: itemId))
          : null,
    );
  }
}
