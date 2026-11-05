import 'package:keepmydiet/features/recipes/domain/recipe_ingredient.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_step.dart';

/// Ce que le formulaire d'une recette envoie, à la création comme à la
/// modification (qui remplace entièrement les ingrédients et les étapes).
class RecipeDraft {
  const RecipeDraft({
    required this.name,
    required this.referenceServings,
    required this.ingredients,
    this.steps = const [],
  });

  final String name;
  final int referenceServings;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;

  Map<String, dynamic> toJson() => {
    'name': name,
    'referenceServings': referenceServings,
    'ingredients': [for (final ingredient in ingredients) ingredient.toJson()],
    'steps': [for (final step in steps) step.toJson()],
  };
}
