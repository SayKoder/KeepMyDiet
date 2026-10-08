import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../meal_plan/presentation/meal_plan_screen.dart';
import 'create_recipe_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipes_controller.dart';

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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MealPlanScreen()),
            ),
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Planning de la semaine',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(recipesControllerProvider.notifier).refresh(),
        child: recipesAsync.when(
          data: (recipes) => recipes.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        "Aucune recette pour l'instant. Ajoute la première !",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return ListTile(
                      leading: const Icon(Icons.restaurant_menu),
                      title: Text(recipe.name),
                      subtitle: Text('${recipe.totalCalories.toStringAsFixed(0)} kcal au total'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur : $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
        ),
        tooltip: 'Ajouter une recette',
        child: const Icon(Icons.add),
      ),
    );
  }
}
