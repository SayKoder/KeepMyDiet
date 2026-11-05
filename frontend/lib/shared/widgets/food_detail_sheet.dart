import 'package:flutter/material.dart';
import 'package:keepmydiet/shared/widgets/macro_pills.dart';

Future<void> showFoodDetailSheet(
  BuildContext context, {
  required String name,
  required double calories,
  required double proteins,
  required double carbs,
  required double fats,
  String? subtitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) Text(subtitle),
            Text(
              '${calories.toStringAsFixed(0)} kcal / 100g',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            MacroPills(proteins: proteins, carbs: carbs, fats: fats),
          ],
        ),
      ),
    ),
  );
}
