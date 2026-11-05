import 'package:flutter/material.dart';

import '../../../../core/theme.dart';

class ExpiringBanner extends StatelessWidget {
  const ExpiringBanner({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = count == 1
        ? '1 aliment périme bientôt'
        : '$count aliments périment bientôt';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      tileColor: AppColors.warningBg,
      textColor: AppColors.warningText,
      iconColor: AppColors.warningText,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.calories.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.timer_outlined, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      subtitle: const Text(
        'Voir les recettes qui les utilisent',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
