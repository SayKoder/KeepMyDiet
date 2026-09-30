import 'recipe_ingredient.dart';

/// `totalCalories`/`totalProteins`/`totalCarbs`/`totalFats` sont calculés à la
/// volée côté backend (jamais stockés) — juste une somme sur les ingrédients,
/// jamais désynchronisables.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.referenceServings,
    required this.ingredients,
    required this.totalCalories,
    required this.totalProteins,
    required this.totalCarbs,
    required this.totalFats,
  });

  final int id;
  final String name;
  final int referenceServings;
  final List<RecipeIngredient> ingredients;
  final double totalCalories;
  final double totalProteins;
  final double totalCarbs;
  final double totalFats;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = (json['ingredients'] as List<dynamic>)
        .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
        .toList();

    return Recipe(
      id: json['id'] as int,
      name: json['name'] as String,
      referenceServings: json['referenceServings'] as int,
      ingredients: ingredients,
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProteins: (json['totalProteins'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      totalFats: (json['totalFats'] as num).toDouble(),
    );
  }
}
