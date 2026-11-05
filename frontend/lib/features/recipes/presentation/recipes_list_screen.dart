import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/meal_plan/presentation/meal_plan_screen.dart';
import 'package:keepmydiet/features/recipes/presentation/create_recipe_screen.dart';
import 'package:keepmydiet/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:keepmydiet/features/recipes/presentation/recipes_controller.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class RecipesListScreen extends ConsumerWidget {
  const RecipesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recettes'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MealPlanScreen())),
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Planning de la semaine',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(recipesControllerProvider.notifier).refresh(),
        child: recipesAsync.toWidget(
          onRetry: () => ref.invalidate(recipesControllerProvider),
          isEmpty: (recipes) => recipes.isEmpty,
          empty: const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Aucune recette',
            message: 'Ajoute la première avec le bouton +.',
          ),
          data: (recipes) => ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: Text(recipe.name),
                subtitle: Text(
                  '${recipe.totalCalories.toStringAsFixed(0)} kcal au total',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(recipe: recipe),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FabAboveNav(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CreateRecipeScreen())),
        tooltip: 'Ajouter une recette',
        child: const Icon(Icons.add),
      ),
    );
  }
}
