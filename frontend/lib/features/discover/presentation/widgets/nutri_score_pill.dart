import 'package:flutter/material.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

const _gradeColors = {
  'A': Color(0xFF038141),
  'B': Color(0xFF85BB2F),
  'C': Color(0xFFFECB02),
  'D': Color(0xFFEE8100),
  'E': Color(0xFFE63E11),
};

class NutriScorePill extends StatelessWidget {
  const NutriScorePill({super.key, required this.grade});

  final String grade;

  @override
  Widget build(BuildContext context) {
    final color = _gradeColors[grade] ?? Colors.grey;

    return Pill(
      label: 'Nutri-Score $grade',
      background: color,
      foreground: grade == 'C' ? Colors.black : Colors.white,
    );
  }
}
