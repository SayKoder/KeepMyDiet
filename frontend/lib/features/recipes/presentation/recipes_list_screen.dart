import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/meal_plan/presentation/meal_plan_screen.dart';
import 'package:keepmydiet/features/recipes/domain/recipe.dart';
import 'package:keepmydiet/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:keepmydiet/features/recipes/presentation/recipe_form_screen.dart';
import 'package:keepmydiet/features/recipes/presentation/recipes_controller.dart';
import 'package:keepmydiet/features/recipes/presentation/widgets/macro_bar.dart';
import 'package:keepmydiet/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

enum RecipeFilter {
  all('Toutes'),
  light('< 500 kcal'),
  protein('Riches en protéines');

  const RecipeFilter(this.label);

  final String label;
}

class RecipesListScreen extends ConsumerStatefulWidget {
  const RecipesListScreen({super.key});

  @override
  ConsumerState<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends ConsumerState<RecipesListScreen> {
  String _query = '';
  RecipeFilter _filter = RecipeFilter.all;

  bool _matches(Recipe recipe) {
    if (!recipe.name.toLowerCase().contains(_query)) return false;
    if (_filter == RecipeFilter.light) return recipe.caloriesPerServing < 500;
    if (_filter == RecipeFilter.protein) return recipe.proteinsPerServing >= 25;
    return true;
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesControllerProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recettes',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _open(const MealPlanScreen()),
                        icon: const Icon(Icons.calendar_month_outlined),
                        tooltip: 'Planning de la semaine',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          minimumSize: const Size(46, 46),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une recette',
                      prefixIcon: Icon(Icons.search),
                      fillColor: Colors.white,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final filter in RecipeFilter.values)
                        _FilterChip(
                          label: filter.label,
                          selected: filter == _filter,
                          onSelected: () => setState(() => _filter = filter),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: ref.read(recipesControllerProvider.notifier).refresh,
                child: recipesAsync.toWidget(
                  onRetry: () => ref.invalidate(recipesControllerProvider),
                  isEmpty: (recipes) => recipes.isEmpty,
                  empty: const EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'Aucune recette',
                    message: 'Ajoute la première avec « Nouvelle recette ».',
                  ),
                  data: (recipes) =>
                      _buildList(recipes.where(_matches).toList()),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FabAboveNav(
        onPressed: () => _open(const RecipeFormScreen()),
        tooltip: 'Nouvelle recette',
        label: 'Nouvelle recette',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Aucune recette ne correspond',
        message: 'Essaie une autre recherche ou un autre filtre.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: recipes.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        if (index == recipes.length) return const MacroLegend();
        final recipe = recipes[index];
        return RecipeCard(
          recipe: recipe,
          onTap: () => _open(RecipeDetailScreen(recipe: recipe)),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      shape: const StadiumBorder(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.ink,
      side: BorderSide(color: selected ? AppColors.ink : AppColors.border),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.ink,
      ),
    );
  }
}
