import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/recipes/data/recipes_api_client.dart';
import 'package:keepmydiet/features/recipes/domain/recipe.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_ingredient.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_step.dart';
import 'package:keepmydiet/shared/local_database.dart';
import 'package:keepmydiet/shared/network_first.dart';

final recipesRepositoryProvider = Provider<RecipesRepository>((ref) {
  return RecipesRepository(
    ref.watch(recipesApiClientProvider),
    ref.watch(localDatabaseProvider),
  );
});

class RecipesRepository {
  RecipesRepository(this._api, this._database);

  final RecipesApiClient _api;
  final LocalDatabase _database;

  Future<List<Recipe>> fetchAll() => networkFirst(
    _database,
    key: 'recipes',
    fetch: _api.fetchAll,
    toJson: (recipes) => [for (final recipe in recipes) recipe.toJson()],
    fromJson: (json) => [
      for (final recipe in json as List)
        Recipe.fromJson(recipe as Map<String, dynamic>),
    ],
  );

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
