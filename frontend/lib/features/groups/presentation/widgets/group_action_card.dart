import 'package:flutter/material.dart';

import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class GroupActionCard extends StatelessWidget {
  const GroupActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: filled
          ? BorderSide.none
          : const BorderSide(color: AppColors.border),
    );

    return Material(
      color: filled ? AppColors.brand : Colors.white,
      shape: shape,
      elevation: filled ? 6 : 0,
      shadowColor: AppColors.brand.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              IconBadge(
                icon: icon,
                background: filled
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.brandLight,
                foreground: filled ? Colors.white : AppColors.brandDark,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
