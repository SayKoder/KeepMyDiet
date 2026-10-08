import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.refresh(shoppingListProvider(widget.groupId).future),
              child: listAsync.when(
                data: (list) {
                  final items = list?.items ?? [];
                  final total = items.length;
                  final checkedCount = _selectedItemIds.length;
                  final progress = total == 0 ? 0.0 : checkedCount / total;

                  final grouped = <String, List<ShoppingListItem>>{};
                  for (final item in items) {
                    grouped.putIfAbsent(item.sourceRecipeName ?? 'Autres articles', () => []).add(item);
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, _selectedItemIds.isEmpty ? 32 : 120),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              minimumSize: const Size(44, 44),
                              shape: const CircleBorder(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Liste de courses', style: Theme.of(context).textTheme.titleLarge),
                                Text(
                                  'Groupe ${widget.groupName}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Material(
                        color: AppColors.brandLight,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: _pickRecipes,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.restaurant_menu, size: 20, color: AppColors.brandDark),
                                SizedBox(width: 8),
                                Text(
                                  'Choisir des recettes',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brandDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            "Aucune ligne pour l'instant. Choisis des recettes pour générer la liste.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Dans le panier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            Text(
                              '$checkedCount / $total',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE3E9E1),
                            valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...grouped.entries.expand(
                          (entry) => [
                            Text(entry.key.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 10),
                            _ItemGroupCard(
                              items: entry.value,
                              selectedIds: _selectedItemIds,
                              onToggle: (id, value) => setState(() {
                                if (value) {
                                  _selectedItemIds.add(id);
                                } else {
                                  _selectedItemIds.remove(id);
                                }
                              }),
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Erreur : $error')),
              ),
            ),
            if (_selectedItemIds.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _CheckoutBar(
                  count: _selectedItemIds.length,
                  onValidate: () => _goToCheckout(listAsync.value?.items ?? []),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemGroupCard extends StatelessWidget {
  const _ItemGroupCard({required this.items, required this.selectedIds, required this.onToggle});

  final List<ShoppingListItem> items;
  final Set<int> selectedIds;
  final void Function(int id, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _ShoppingItemRow(
              item: items[i],
              checked: selectedIds.contains(items[i].id),
              showDivider: i > 0,
              onChanged: (value) => onToggle(items[i].id, value),
            ),
        ],
      ),
    );
  }
}

class _ShoppingItemRow extends StatelessWidget {
  const _ShoppingItemRow({
    required this.item,
    required this.checked,
    required this.showDivider,
    required this.onChanged,
  });

  final ShoppingListItem item;
  final bool checked;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: showDivider ? const Border(top: BorderSide(color: Color(0xFFEEF2EC))) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? AppColors.brand : null,
                border: checked ? null : Border.all(color: const Color(0xFFC9D1C8), width: 2),
              ),
              child: checked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: checked ? AppColors.iconMuted : AppColors.ink,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(
              '${item.quantity.toStringAsFixed(0)} ${item.unit}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: checked ? AppColors.iconMuted : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.count, required this.onValidate});

  final int count;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.25), blurRadius: 32, offset: const Offset(0, 14))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count article${count > 1 ? 's' : ''} coché${count > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'À ranger au frigo ou au placard',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.limeAccent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onValidate,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                child: const Text('Valider', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
            ),
          ),
        ],
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
