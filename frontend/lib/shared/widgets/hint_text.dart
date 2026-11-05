import 'package:flutter/material.dart';
import 'package:keepmydiet/core/theme.dart';

class HintText extends StatelessWidget {
  const HintText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
  }
}
