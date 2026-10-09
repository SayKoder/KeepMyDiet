import '../../fridge/domain/fridge_item.dart';
import 'meal_plan_entry.dart';

class MissingIngredient {
  const MissingIngredient({
    required this.name,
    required this.missingQuantity,
    required this.unit,
  });

  final String name;
  final double missingQuantity;
  final String unit;
}

/// Comparaison approximative par nom (insensible à la casse) entre ce qui
/// est prévu sur les créneaux visibles et le stock actuel (frigo + placard
/// confondus) — même limite déjà acceptée côté backend pour l'autocomplete
/// d'ingrédients et la génération de liste depuis le planning (pas de FK
/// entre `RecipeIngredient` et `FoodReference`). Calculé côté client : les
/// mêmes données (recettes + frigo) sont déjà chargées par ailleurs, pas
/// besoin d'un endpoint dédié pour ça.
List<MissingIngredient> computeMissingIngredients(
  List<MealPlanEntry> entries,
  List<FridgeItem> fridgeItems,
) {
  final needed = <String, ({String name, String unit, double quantity})>{};
  for (final entry in entries) {
    for (final ingredient in entry.recipe.ingredients) {
      final key = '${ingredient.name.toLowerCase()}|${ingredient.unit}';
      final current = needed[key];
      needed[key] = (
        name: ingredient.name,
        unit: ingredient.unit,
        quantity: (current?.quantity ?? 0) + ingredient.quantity * entry.ratio,
      );
    }
  }

  final stock = <String, double>{};
  for (final item in fridgeItems) {
    final key = '${item.foodReference.name.toLowerCase()}|${item.unit}';
    stock[key] = (stock[key] ?? 0) + item.quantity;
  }

  final missing = <MissingIngredient>[];
  for (final entry in needed.entries) {
    final remaining = entry.value.quantity - (stock[entry.key] ?? 0);
    if (remaining > 0) {
      missing.add(
        MissingIngredient(
          name: entry.value.name,
          missingQuantity: remaining,
          unit: entry.value.unit,
        ),
      );
    }
  }

  return missing;
}
