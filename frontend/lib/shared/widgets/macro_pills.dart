import 'package:flutter/material.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/shared/widgets/pill.dart';

class MacroPills extends StatelessWidget {
  const MacroPills({
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Pill(
          label: 'Protéines ${proteins.toStringAsFixed(1)} g',
          background: AppColors.proteinBg,
          foreground: AppColors.proteinIcon,
        ),
        Pill(
          label: 'Glucides ${carbs.toStringAsFixed(1)} g',
          background: AppColors.carbsBg,
          foreground: AppColors.carbsIcon,
        ),
        Pill(
          label: 'Lipides ${fats.toStringAsFixed(1)} g',
          background: AppColors.fatBg,
          foreground: AppColors.fatIcon,
        ),
      ],
    );
  }
}
