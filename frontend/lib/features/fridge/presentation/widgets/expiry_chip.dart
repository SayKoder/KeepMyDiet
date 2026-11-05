import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:keepmydiet/core/theme.dart';

class ExpiryChip extends StatelessWidget {
  const ExpiryChip({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final daysLeft = DateUtils.dateOnly(date).difference(today).inDays;
    final urgent = daysLeft < 3;

    final label = switch (daysLeft) {
      < 0 => 'Périmé',
      0 => "Aujourd'hui",
      1 => 'Demain',
      2 => 'Dans 2 j',
      _ => DateFormat('dd/MM').format(date),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: urgent ? AppColors.errorBg : AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: urgent ? AppColors.errorText : AppColors.textSecondary,
        ),
      ),
    );
  }
}
