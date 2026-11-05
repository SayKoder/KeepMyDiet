import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:keepmydiet/features/recipes/domain/recipe.dart';
import 'package:keepmydiet/features/recipes/presentation/recipes_controller.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

typedef SaveMealEntry = Future<MealPlanEntry> Function({
  required int recipeId,
  required int servings,
});

class ExistingRecipeTab extends ConsumerStatefulWidget {
  const ExistingRecipeTab({super.key, required this.saveEntry});

  final SaveMealEntry saveEntry;

  @override
  ConsumerState<ExistingRecipeTab> createState() => _ExistingRecipeTabState();
}

class _ExistingRecipeTabState extends ConsumerState<ExistingRecipeTab> {
  final _servingsController = TextEditingController(text: '1');
  Recipe? _selectedRecipe;
  String _filter = '';
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _servingsController.dispose();
    super.dispose();
  }

  String? _validate(int? servings) {
    if (_selectedRecipe == null) return 'Choisis une recette dans la liste.';
    if (servings == null || servings <= 0) {
      return 'Le nombre de portions doit être positif.';
    }
    return null;
  }

  Future<void> _submit() async {
    final servings = int.tryParse(_servingsController.text);
    final error = _validate(servings);

    setState(() {
      _error = error;
      _isSubmitting = error == null;
    });
    if (error != null) return;

    try {
      final entry = await widget.saveEntry(
        recipeId: _selectedRecipe!.id,
        servings: servings!,
      );
      if (mounted) Navigator.of(context).pop(entry);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) =>
                setState(() => _filter = value.trim().toLowerCase()),
            decoration: const InputDecoration(
              labelText: 'Rechercher une recette',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: recipesAsync.toWidget(
            onRetry: () => ref.invalidate(recipesControllerProvider),
            data: _buildRecipeList,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              NumberField(
                controller: _servingsController,
                label: 'Nombre de portions prévues',
                decimal: false,
              ),
              if (_error != null)
                FormErrorText(_error!, padding: EdgeInsets.zero),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: SubmitButtonContent(
                  isSubmitting: _isSubmitting,
                  label: const Text('Ajouter au planning'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeList(List<Recipe> recipes) {
    final filtered = recipes
        .where((recipe) => recipe.name.toLowerCase().contains(_filter))
        .toList();

    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Aucune recette ne correspond',
      );
    }

    return RadioGroup<int>(
      groupValue: _selectedRecipe?.id,
      onChanged: (id) => setState(
        () => _selectedRecipe = filtered.firstWhere((r) => r.id == id),
      ),
      child: ListView(
        children: [
          for (final recipe in filtered)
            RadioListTile<int>(
              value: recipe.id,
              title: Text(recipe.name),
              subtitle: Text(
                '${recipe.totalCalories.toStringAsFixed(0)} kcal pour '
                '${recipe.referenceServings} pers.',
              ),
            ),
        ],
      ),
    );
  }
}
