import 'package:beltei_app/data/models/app_user.dart';
import 'package:flutter/material.dart';

class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({
    super.key,
    required this.stats,
    this.onLostTap,
    this.onFoundTap,
    this.onClaimsTap,
    this.onResolvedTap,
  });

  final ProfileStats stats;
  final VoidCallback? onLostTap;
  final VoidCallback? onFoundTap;
  final VoidCallback? onClaimsTap;
  final VoidCallback? onResolvedTap;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Lost posts', stats.myLost, Icons.search_off, onLostTap),
      ('Found posts', stats.myFound, Icons.inventory_2_outlined, onFoundTap),
      ('Claims', stats.myClaims, Icons.fact_check_outlined, onClaimsTap),
      ('Resolved', stats.myResolved, Icons.check_circle_outline, onResolvedTap),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: cards
          .map(
            (c) => Card(
              child: InkWell(
                onTap: c.$4,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(c.$3, size: 20, color: Theme.of(context).colorScheme.primary),
                      const Spacer(),
                      Text(c.$1, style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        '${c.$2}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
