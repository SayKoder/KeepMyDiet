import 'package:flutter/material.dart';

import 'package:keepmydiet/features/meal_plan/domain/missing_ingredient.dart';

Future<void> showMissingIngredientsSheet(
  BuildContext context,
  List<MissingIngredient> missing,
) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Ce qui manque cette semaine',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (missing.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Tout est déjà au frigo/placard pour les repas prévus.',
              ),
            ),
          for (final item in missing)
            ListTile(
              dense: true,
              leading: const Icon(Icons.shopping_basket_outlined),
              title: Text(item.name),
              trailing: Text(
                '${item.missingQuantity.toStringAsFixed(0)} ${item.unit}',
              ),
            ),
        ],
      ),
    ),
  );
}
