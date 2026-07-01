import 'package:beltei_app/core/constants/lost_found_constants.dart';
import 'package:beltei_app/core/theme/app_colors.dart';
import 'package:beltei_app/core/utils/date_format.dart';
import 'package:beltei_app/data/models/lost_found_item.dart';
import 'package:beltei_app/widgets/type_badge.dart';
import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, this.onTap});

  final LostFoundItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Image.network(
                item.imageUrl!,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(context),
              )
            else
              _imagePlaceholder(context),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TypeBadge(type: item.type),
                      const Spacer(),
                      Text(
                        formatEventDate(item.eventDate),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item.building}${item.roomHint != null ? ' · ${item.roomHint}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LostFoundConstants.categoryLabel[item.category] ??
                        item.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      height: 120,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceMutedDark
          : AppColors.surfaceMutedLight,
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
    );
  }
}
