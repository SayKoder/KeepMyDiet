import 'package:keepmydiet/features/recipes/domain/recipe_ingredient.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_step.dart';

/// `totalCalories`/`totalProteins`/`totalCarbs`/`totalFats` sont calculés à la
/// volée côté backend (jamais stockés) — juste une somme sur les ingrédients,
/// jamais désynchronisables.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.referenceServings,
    required this.ingredients,
    required this.steps,
    required this.totalCalories,
    required this.totalProteins,
    required this.totalCarbs,
    required this.totalFats,
    this.canEdit = false,
  });

  final int id;
  final String name;
  final int referenceServings;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final double totalCalories;
  final double totalProteins;
  final double totalCarbs;
  final double totalFats;
  final bool canEdit;

  int get _servings => referenceServings <= 0 ? 1 : referenceServings;

  double get caloriesPerServing => totalCalories / _servings;
  double get proteinsPerServing => totalProteins / _servings;

  int get totalMinutes {
    var total = 0;
    for (final step in steps) {
      total += step.durationMinutes ?? 0;
    }
    return total;
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = (json['ingredients'] as List<dynamic>)
        .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
        .toList();
    final steps = (json['steps'] as List<dynamic>? ?? [])
        .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
        .toList();

    return Recipe(
      id: json['id'] as int,
      name: json['name'] as String,
      referenceServings: json['referenceServings'] as int,
      ingredients: ingredients,
      steps: steps,
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProteins: (json['totalProteins'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      totalFats: (json['totalFats'] as num).toDouble(),
      canEdit: json['canEdit'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'referenceServings': referenceServings,
    'ingredients': [for (final ingredient in ingredients) ingredient.toJson()],
    'steps': [for (final step in steps) step.toJson()],
    'totalCalories': totalCalories,
    'totalProteins': totalProteins,
    'totalCarbs': totalCarbs,
    'totalFats': totalFats,
    'canEdit': canEdit,
  };
}
