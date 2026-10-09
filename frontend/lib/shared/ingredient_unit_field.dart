import 'package:flutter/material.dart';

/// Unités utilisables pour une quantité d'ingrédient/aliment : masse (g/kg),
/// volume (cL/L) et "pièce" pour ce qui se compte plutôt que se pèse (une
/// tomate, une banane...).
const List<String> ingredientUnits = ['g', 'kg', 'cL', 'L', 'pièce'];

/// Liste déroulante stylisée pour le champ "Unité" des formulaires d'ajout
/// d'ingrédient (Frigo, Recette) — remplace le `TextField` libre d'avant.
/// Garde un `TextEditingController` en source de vérité, comme les autres
/// champs de ces formulaires (et parce que `create_recipe_screen` y écrit
/// directement quand on reprend une suggestion d'ingrédient).
class IngredientUnitField extends StatelessWidget {
  const IngredientUnitField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final current = controller.text.trim();
    // Une suggestion ou une valeur déjà enregistrée peut porter une unité
    // hors de cette liste (ancienne saisie libre) — on l'ajoute en tête
    // plutôt que de la perdre silencieusement.
    final options =
        current.isEmpty || ingredientUnits.contains(current) ? ingredientUnits : [current, ...ingredientUnits];

    return DropdownButtonFormField<String>(
      // `DropdownButtonFormField` n'est pas "contrôlé" : son état interne ne
      // se resynchronise pas tout seul quand `controller.text` change depuis
      // l'extérieur (ex: `_applySuggestion`) — cette clé force un remount
      // avec la bonne valeur initiale à chaque fois que ce texte change.
      key: ValueKey(current),
      initialValue: current.isEmpty ? ingredientUnits.first : current,
      decoration: const InputDecoration(labelText: 'Unité'),
      items: options.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
      onChanged: (value) {
        if (value != null) {
          controller.text = value;
        }
      },
    );
  }
}
