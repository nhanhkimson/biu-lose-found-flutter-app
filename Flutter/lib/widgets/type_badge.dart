import 'package:beltei_app/core/constants/lost_found_constants.dart';
import 'package:beltei_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLost = type == 'LOST';
    final fg = isLost
        ? (isDark ? AppColors.lostDark : AppColors.lostForegroundLight)
        : (isDark ? AppColors.foundDark : AppColors.foundForegroundLight);
    final bg = isLost
        ? (isDark ? AppColors.lostMutedDark : AppColors.lostMutedLight)
        : (isDark ? AppColors.foundMutedDark : AppColors.foundMutedLight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        LostFoundConstants.typeLabel[type] ?? type,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
