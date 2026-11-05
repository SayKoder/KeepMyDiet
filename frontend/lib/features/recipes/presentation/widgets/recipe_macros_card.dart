import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/recipes/domain/recipe.dart';

class RecipeMacrosCard extends StatelessWidget {
  const RecipeMacrosCard({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern('fr_FR');

    return Card(
      elevation: 6,
      shadowColor: AppColors.ink.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _MacroColumn(
                value: number.format(recipe.totalCalories.round()),
                label: 'kcal',
                color: AppColors.calories,
              ),
              const VerticalDivider(color: AppColors.border),
              _MacroColumn(
                value: '${recipe.totalProteins.round()} g',
                label: 'Prot.',
                color: AppColors.protein,
              ),
              const VerticalDivider(color: AppColors.border),
              _MacroColumn(
                value: '${recipe.totalCarbs.round()} g',
                label: 'Gluc.',
                color: AppColors.carbs,
              ),
              const VerticalDivider(color: AppColors.border),
              _MacroColumn(
                value: '${recipe.totalFats.round()} g',
                label: 'Lip.',
                color: AppColors.fat,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroColumn extends StatelessWidget {
  const _MacroColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        spacing: 2,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 5,
            children: [
              CircleAvatar(radius: 3.5, backgroundColor: color),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
