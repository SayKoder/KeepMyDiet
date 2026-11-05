import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/async_value_ui.dart';
import '../../../recipes/domain/recipe.dart';
import '../../../recipes/presentation/recipes_controller.dart';

// Renvoie les ids des recettes cochées.
Future<List<int>?> showRecipePickerSheet(BuildContext context) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _RecipePickerSheet(),
  );
}

class _RecipePickerSheet extends ConsumerStatefulWidget {
  const _RecipePickerSheet();

  @override
  ConsumerState<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends ConsumerState<_RecipePickerSheet> {
  final Set<int> _selected = {};

  void _toggle(int id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              'Choisir des recettes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Flexible(
              child: recipesAsync.toWidget(
                onRetry: () => ref.invalidate(recipesControllerProvider),
                isEmpty: (recipes) => recipes.isEmpty,
                empty: const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'Aucune recette disponible',
                  message: 'Crée-en une avant de générer une liste.',
                ),
                data: _buildList,
              ),
            ),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected.toList()),
              child: Text('Ajouter ${_selected.length} recette(s) à la liste'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Recipe> recipes) {
    return ListView(
      shrinkWrap: true,
      children: [
        for (final recipe in recipes)
          CheckboxListTile(
            value: _selected.contains(recipe.id),
            onChanged: (_) => _toggle(recipe.id),
            title: Text(recipe.name),
            subtitle: Text(
              '${recipe.ingredients.length} ingrédients — pour '
              '${recipe.referenceServings} pers.',
            ),
          ),
      ],
    );
  }
}
