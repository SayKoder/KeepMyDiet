import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/groups/presentation/group_events_controller.dart';
import 'package:keepmydiet/features/shopping_list/domain/shopping_list_item.dart';
import 'package:keepmydiet/features/shopping_list/presentation/add_shopping_item_screen.dart';
import 'package:keepmydiet/features/shopping_list/presentation/shopping_list_checkout_screen.dart';
import 'package:keepmydiet/features/shopping_list/presentation/shopping_list_controller.dart';
import 'package:keepmydiet/features/shopping_list/presentation/widgets/checkout_bar.dart';
import 'package:keepmydiet/features/shopping_list/presentation/widgets/recipe_picker_sheet.dart';
import 'package:keepmydiet/features/shopping_list/presentation/widgets/shopping_item_group.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final int groupId;
  final String groupName;

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final Set<int> _selectedIds = {};

  void _toggle(int id) => setState(() {
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
  });

  Future<void> _pickRecipes() async {
    final recipeIds = await showRecipePickerSheet(context);
    if (recipeIds == null || recipeIds.isEmpty || !mounted) return;

    try {
      await generateShoppingList(
        ref,
        groupId: widget.groupId,
        recipeIds: recipeIds,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _addFood() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AddShoppingItemScreen(groupId: widget.groupId),
    ),
  );

  Future<void> _goToCheckout(List<ShoppingListItem> items) async {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShoppingListCheckoutScreen(
          groupId: widget.groupId,
          items: items.where((i) => _selectedIds.contains(i.id)).toList(),
        ),
      ),
    );
    if (success == true) setState(_selectedIds.clear);
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListProvider(widget.groupId));
    final items = listAsync.value?.items ?? const <ShoppingListItem>[];
    ref.onGroupEvent(
      widget.groupId,
      'shopping_list',
      () => ref.invalidate(shoppingListProvider(widget.groupId)),
    );

    return LiveRefresh(
      interval: liveRefreshInterval,
      onRefresh: () => ref.invalidate(shoppingListProvider(widget.groupId)),
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.refresh(shoppingListProvider(widget.groupId).future),
            child: listAsync.toWidget(
              onRetry: () =>
                  ref.invalidate(shoppingListProvider(widget.groupId)),
              data: (_) => _buildList(items),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _selectedIds.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CheckoutBar(
                  count: _selectedIds.length,
                  onValidate: () => _goToCheckout(items),
                ),
              ),
      ),
    );
  }

  Widget _buildList(List<ShoppingListItem> items) {
    final byRecipe = <String, List<ShoppingListItem>>{};
    for (final item in items) {
      (byRecipe[item.sourceRecipeName ?? 'Autres articles'] ??= []).add(item);
    }
    final progress = items.isEmpty ? 0.0 : _selectedIds.length / items.length;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, _selectedIds.isEmpty ? 32 : 120),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const RoundBackButton(),
          title: Text(
            'Liste de courses',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            'Groupe ${widget.groupName}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _pickRecipes,
          icon: const Icon(Icons.restaurant_menu, size: 20),
          label: const Text('Choisir des recettes'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandLight,
            foregroundColor: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addFood,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Ajouter un aliment'),
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Liste vide',
            message: 'Choisis des recettes ou ajoute un aliment.',
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dans le panier',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                '${_selectedIds.length} / ${items.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: AppColors.border,
            color: AppColors.brand,
          ),
          for (final MapEntry(key: recipeName, value: recipeItems)
              in byRecipe.entries)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: ShoppingItemGroup(
                title: recipeName,
                items: recipeItems,
                selectedIds: _selectedIds,
                onToggle: _toggle,
              ),
            ),
        ],
      ],
    );
  }
}
