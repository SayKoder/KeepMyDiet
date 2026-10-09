import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_bottom_nav.dart';
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
      // Sans ce décalage, le FAB se positionne juste au-dessus de la pilule
      // (le `Scaffold` imbriqué gère déjà correctement cette marge tout seul)
      // mais sa moitié basse reste prise dans le dégradé de HomeShell, qui
      // l'estompe comme s'il était passé dessous — même hauteur que ce
      // dégradé (`fadeHeight` dans home_shell.dart) pour passer juste au-dessus.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: AppBottomNav.floatingClearance(context) / 2),
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
          ),
          tooltip: 'Ajouter une recette',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
