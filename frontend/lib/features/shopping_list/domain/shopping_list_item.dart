/// Une ligne de la liste de courses. Macros déjà pour 100g (convention
/// FoodReference) — pas pour la quantité de la ligne (convention
/// RecipeIngredient côté backend), la conversion est faite une fois pour
/// toutes côté serveur au moment de `generate`.
class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    required this.sourceRecipeName,
  });

  final int id;
  final String name;
  final double quantity;
  final String unit;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final String? sourceRecipeName;

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) => ShoppingListItem(
        id: json['id'] as int,
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        caloriesPer100g: (json['caloriesPer100g'] as num).toDouble(),
        proteinsPer100g: (json['proteinsPer100g'] as num).toDouble(),
        carbsPer100g: (json['carbsPer100g'] as num).toDouble(),
        fatsPer100g: (json['fatsPer100g'] as num).toDouble(),
        sourceRecipeName: json['sourceRecipeName'] as String?,
      );
}
