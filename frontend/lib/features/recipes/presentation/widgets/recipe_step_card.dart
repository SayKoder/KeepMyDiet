import 'package:flutter/material.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_step.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class RecipeStepCard extends StatelessWidget {
  const RecipeStepCard({super.key, required this.number, required this.step});

  final int number;
  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    final minutes = step.durationMinutes;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      leading: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      title: Text(
        step.instruction,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: minutes == null
          ? null
          : Pill(
              label: '$minutes min',
              background: AppColors.brandLight,
              foreground: AppColors.brandDark,
            ),
    );
  }
}
