import 'package:beltei_app/core/constants/lost_found_constants.dart';
import 'package:beltei_app/data/models/profile_activity.dart';
import 'package:beltei_app/screens/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProfileActivityList extends StatelessWidget {
  const ProfileActivityList({super.key, required this.activities});

  final List<ProfileActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No recent listings or claims yet. Report a lost or found item to see activity here.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final a = activities[index];
          final subtitle = a.isItem
              ? '${LostFoundConstants.typeLabel[a.type] ?? a.type} · ${LostFoundConstants.statusLabel[a.status] ?? a.status}'
              : 'Claim · ${a.claimStatus}';
          return ListTile(
            leading: Icon(
              a.isItem
                  ? (a.type == 'LOST' ? Icons.search_off : Icons.inventory_2_outlined)
                  : Icons.fact_check_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              a.isClaim ? 'Claim: ${a.title}' : a.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '$subtitle · ${DateFormat.MMMd().format(a.at.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => ItemDetailScreen(itemId: a.itemId)),
          );
        },
      ),
    );
  }
}
