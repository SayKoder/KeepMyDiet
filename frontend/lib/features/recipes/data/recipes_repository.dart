import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/recipes/data/recipes_api_client.dart';
import 'package:keepmydiet/features/recipes/domain/recipe.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_ingredient.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_step.dart';

final recipesRepositoryProvider = Provider<RecipesRepository>((ref) {
  return RecipesRepository(ref.watch(recipesApiClientProvider));
});

class RecipesRepository {
  RecipesRepository(this._api);

  final RecipesApiClient _api;

  Future<List<Recipe>> fetchAll() => _api.fetchAll();

  Future<Recipe> create({
    required String name,
    required int referenceServings,
    required List<RecipeIngredient> ingredients,
    List<RecipeStep> steps = const [],
  }) => _api.create(
    name: name,
    referenceServings: referenceServings,
    ingredients: ingredients,
    steps: steps,
  );

  Future<void> delete(int id) => _api.delete(id);

  Future<List<RecipeIngredient>> suggestIngredients(String query) =>
      _api.suggestIngredients(query);
}
