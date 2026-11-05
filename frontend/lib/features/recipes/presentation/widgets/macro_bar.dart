import 'package:flutter/material.dart';
import 'package:keepmydiet/core/theme.dart';

// Répartition des calories : protéines et glucides = 4 kcal/g, lipides = 9.
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.proteins,
    required this.carbs,
    required this.fats,
  });

  final double proteins;
  final double carbs;
  final double fats;

  @override
  Widget build(BuildContext context) {
    final proteinKcal = (proteins * 4).round();
    final carbKcal = (carbs * 4).round();
    final fatKcal = (fats * 9).round();

    if (proteinKcal + carbKcal + fatKcal == 0) {
      return const _Segment(flex: 1, color: AppColors.border);
    }

    return Row(
      spacing: 2,
      children: [
        if (proteinKcal > 0)
          _Segment(flex: proteinKcal, color: AppColors.protein),
        if (carbKcal > 0) _Segment(flex: carbKcal, color: AppColors.carbs),
        if (fatKcal > 0) _Segment(flex: fatKcal, color: AppColors.fat),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.flex, required this.color});

  final int flex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class MacroLegend extends StatelessWidget {
  const MacroLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      children: [
        _LegendItem(color: AppColors.protein, label: 'Protéines'),
        _LegendItem(color: AppColors.carbs, label: 'Glucides'),
        _LegendItem(color: AppColors.fat, label: 'Lipides'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
