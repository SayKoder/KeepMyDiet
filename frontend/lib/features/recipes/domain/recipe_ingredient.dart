/// Miroir de `RecipeIngredient` côté backend : les macros sont déjà calculées
/// pour CETTE quantité précise (pas pour 100g) — pas de conversion d'unité
/// tant qu'il n'existe pas de vraie base aliments (voir JOURNAL.md, étape 8).
class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
  });

  final String name;
  final double quantity;
  final String unit;
  final double calories;
  final double proteins;
  final double carbs;
  final double fats;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        calories: (json['calories'] as num).toDouble(),
        proteins: (json['proteins'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fats: (json['fats'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'calories': calories,
    'proteins': proteins,
    'carbs': carbs,
    'fats': fats,
  };
}
