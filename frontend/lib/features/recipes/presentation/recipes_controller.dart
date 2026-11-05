import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/meal_plan/presentation/meal_plan_controller.dart';
import 'package:keepmydiet/features/recipe_suggestions/presentation/recipe_suggestions_controller.dart';
import 'package:keepmydiet/features/recipes/data/recipes_repository.dart';
import 'package:keepmydiet/features/recipes/domain/recipe.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_draft.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_failure.dart';
import 'package:keepmydiet/shared/api_client.dart';

final recipesControllerProvider =
    AsyncNotifierProvider<RecipesController, List<Recipe>>(
      RecipesController.new,
    );

/// Contrairement à `GroupsController`, pas besoin d'observer la session ici :
/// le pool de recettes est le même pour tout le monde, se déconnecter puis se
/// reconnecter avec un autre compte ne change pas ce qu'il faut afficher.
class RecipesController extends AsyncNotifier<List<Recipe>> {
  @override
  Future<List<Recipe>> build() {
    return ref.read(recipesRepositoryProvider).fetchAll();
  }

  Future<Recipe> create(RecipeDraft draft) async {
    final Recipe recipe;
    try {
      recipe = await ref.read(recipesRepositoryProvider).create(draft);
    } on DioException catch (e) {
      throw RecipeFailure(extractErrorMessage(e));
    }

    state = AsyncData([...state.value ?? [], recipe]);

    return recipe;
  }

  Future<Recipe> updateRecipe(int id, RecipeDraft draft) async {
    final Recipe recipe;
    try {
      recipe = await ref.read(recipesRepositoryProvider).update(id, draft);
    } on DioException catch (e) {
      throw RecipeFailure(extractErrorMessage(e));
    }

    state = AsyncData([
      for (final r in state.value ?? <Recipe>[]) r.id == id ? recipe : r,
    ]);
    // Le planning et les suggestions affichent aussi cette recette.
    ref
      ..invalidate(mealPlanEntriesProvider)
      ..invalidate(mealPlanEntriesForDateProvider)
      ..invalidate(recipeSuggestionsProvider);

    return recipe;
  }

  Future<void> delete(int id) async {
    try {
      await ref.read(recipesRepositoryProvider).delete(id);
    } on DioException catch (e) {
      throw RecipeFailure(extractErrorMessage(e));
    }

    state = AsyncData((state.value ?? []).where((r) => r.id != id).toList());
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(recipesRepositoryProvider).fetchAll(),
    );
  }
}
