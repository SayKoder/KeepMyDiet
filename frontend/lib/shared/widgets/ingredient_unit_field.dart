import 'package:flutter/material.dart';

const List<String> ingredientUnits = ['g', 'kg', 'cL', 'L', 'pièce'];

class IngredientUnitField extends StatelessWidget {
  const IngredientUnitField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final current = controller.text.trim();
    // Une unité hors liste (ancienne saisie libre) est ajoutée en tête.
    final options = current.isEmpty || ingredientUnits.contains(current)
        ? ingredientUnits
        : [current, ...ingredientUnits];

    return DropdownButtonFormField<String>(
      // La clé force un remount quand le texte change depuis l'extérieur.
      key: ValueKey(current),
      initialValue: current.isEmpty ? ingredientUnits.first : current,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Unité'),
      items: options
          .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          controller.text = value;
        }
      },
    );
  }
}
