import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../../../shared/widgets/white_card.dart';

class MacroCard extends StatelessWidget {
  const MacroCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.barColor,
    required this.label,
    required this.consumedG,
    required this.targetG,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color barColor;
  final String label;
  final double consumedG;
  final double targetG;

  @override
  Widget build(BuildContext context) {
    final progress = targetG <= 0 ? 0.0 : (consumedG / targetG).clamp(0.0, 1.0);

    return WhiteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: icon,
            background: iconBg,
            foreground: iconColor,
            size: 34,
            radius: 12,
          ),
          const SizedBox(height: 10),
          Text(
            '${consumedG.round()} g',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '/ ${targetG.round()} g',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.iconMuted,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: AppColors.fieldFill,
            color: barColor,
          ),
        ],
      ),
    );
  }
}
