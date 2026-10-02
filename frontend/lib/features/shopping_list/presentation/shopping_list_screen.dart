import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recipes/domain/recipe.dart';
import '../../recipes/presentation/recipes_controller.dart';
import '../domain/shopping_list_item.dart';
import 'shopping_list_checkout_screen.dart';
import 'shopping_list_controller.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key, required this.groupId, required this.groupName});

  final int groupId;
  final String groupName;

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final Set<int> _selectedItemIds = {};

  Future<void> _pickRecipes() async {
    final recipeIds = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RecipePickerSheet(groupId: widget.groupId),
    );
    if (recipeIds == null || recipeIds.isEmpty || !mounted) {
      return;
    }

    try {
      await generateShoppingList(ref, groupId: widget.groupId, recipeIds: recipeIds);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _goToCheckout(List<ShoppingListItem> allItems) async {
    final selected = allItems.where((i) => _selectedItemIds.contains(i.id)).toList();
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShoppingListCheckoutScreen(groupId: widget.groupId, items: selected),
      ),
    );
    if (success == true) {
      setState(() => _selectedItemIds.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Liste de courses — ${widget.groupName}'),
        actions: [
          IconButton(
            onPressed: _pickRecipes,
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Choisir des recettes',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(shoppingListProvider(widget.groupId).future),
        child: listAsync.when(
          data: (list) {
            final items = list?.items ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      "Aucune ligne pour l'instant. Choisis des recettes pour générer la liste.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final checked = _selectedItemIds.contains(item.id);

                return CheckboxListTile(
                  value: checked,
                  onChanged: (value) => setState(() {
                    if (value ?? false) {
                      _selectedItemIds.add(item.id);
                    } else {
                      _selectedItemIds.remove(item.id);
                    }
                  }),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.quantity.toStringAsFixed(0)} ${item.unit}'
                    '${item.sourceRecipeName != null ? ' — pour ${item.sourceRecipeName}' : ''}',
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur : $error')),
        ),
      ),
      floatingActionButton: _selectedItemIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _goToCheckout(listAsync.value?.items ?? []),
              icon: const Icon(Icons.check),
              label: Text('Valider (${_selectedItemIds.length})'),
            ),
    );
  }
}

/// Sélection multiple de recettes (cases à cocher), renvoie leurs ids via
/// `Navigator.pop` — CLAUDE.md : "Sélection des recettes souhaitées pour la
/// semaine → validation via cases à cocher."
class _RecipePickerSheet extends ConsumerStatefulWidget {
  const _RecipePickerSheet({required this.groupId});

  final int groupId;

  @override
  ConsumerState<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends ConsumerState<_RecipePickerSheet> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choisir des recettes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Flexible(
              child: recipesAsync.when(
                data: (recipes) => _RecipeCheckboxList(
                  recipes: recipes,
                  selected: _selected,
                  onToggle: (id, value) => setState(() {
                    if (value) {
                      _selected.add(id);
                    } else {
                      _selected.remove(id);
                    }
                  }),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erreur : $error'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
              child: Text('Ajouter ${_selected.length} recette(s) à la liste'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCheckboxList extends StatelessWidget {
  const _RecipeCheckboxList({required this.recipes, required this.selected, required this.onToggle});

  final List<Recipe> recipes;
  final Set<int> selected;
  final void Function(int id, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Aucune recette disponible — crée-en une avant de générer une liste.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];

        return CheckboxListTile(
          value: selected.contains(recipe.id),
          onChanged: (value) => onToggle(recipe.id, value ?? false),
          title: Text(recipe.name),
          subtitle: Text('${recipe.ingredients.length} ingrédients — pour ${recipe.referenceServings} pers.'),
        );
      },
    );
  }
}
