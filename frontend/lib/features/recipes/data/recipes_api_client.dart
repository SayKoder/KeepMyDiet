import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../domain/recipe.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_step.dart';

final recipesApiClientProvider = Provider<RecipesApiClient>((ref) {
  return RecipesApiClient(ref.watch(dioProvider));
});

/// Pool global : tous les utilisateurs voient les mêmes recettes (pas de
/// provider custom côté backend, contrairement à `/groups` qui filtre par
/// utilisateur — voir JOURNAL.md, étape 8).
class RecipesApiClient {
  RecipesApiClient(this._dio);

  final Dio _dio;
  static final _ldJson = Options(contentType: 'application/ld+json');

  Future<List<Recipe>> fetchAll() async {
    final response = await _dio.get<Map<String, dynamic>>('/recipes');
    final members = response.data!['member'] as List<dynamic>;

    return members.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Recipe> create({
    required String name,
    required int referenceServings,
    required List<RecipeIngredient> ingredients,
    List<RecipeStep> steps = const [],
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/recipes',
      data: {
        'name': name,
        'referenceServings': referenceServings,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'steps': steps.map((s) => s.toJson()).toList(),
      },
      options: _ldJson,
    );

    return Recipe.fromJson(response.data!);
  }

  /// Réservé au créateur — le backend renvoie un 403 sinon (`security` sur
  /// l'opération Delete), remonté comme une erreur classique.
  Future<void> delete(int id) async {
    await _dio.delete<void>('/recipes/$id');
  }

  /// Autocomplete à la création d'une recette : noms d'ingrédients déjà
  /// utilisés ailleurs, avec leurs macros, pour éviter la ressaisie. `query`
  /// de moins de 2 caractères renvoie toujours une liste vide côté backend.
  Future<List<RecipeIngredient>> suggestIngredients(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/ingredient_suggestions',
      queryParameters: {'query': query},
    );
    final members = response.data!['member'] as List<dynamic>;

    return members.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>)).toList();
  }
}
