import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';
import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/features/shopping_list/presentation/shopping_list_controller.dart';

class AddToListButton extends ConsumerStatefulWidget {
  const AddToListButton({super.key, required this.product, this.label});

  final OpenFoodFactsProduct product;
  final String? label;

  @override
  ConsumerState<AddToListButton> createState() => _AddToListButtonState();
}

class _AddToListButtonState extends ConsumerState<AddToListButton> {
  bool _isAdding = false;

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _add(int? groupId) async {
    if (groupId == null) {
      _showMessage(
        'Rejoins ou crée un groupe pour utiliser la liste de courses.',
      );
      return;
    }

    final product = widget.product;
    setState(() => _isAdding = true);
    try {
      await addShoppingListItem(
        ref,
        groupId: groupId,
        name: product.name,
        quantity: 1,
        unit: 'pièce',
        caloriesPer100g: product.caloriesPer100g,
        proteinsPer100g: product.proteinsPer100g,
        carbsPer100g: product.carbsPer100g,
        fatsPer100g: product.fatsPer100g,
      );
      if (mounted) {
        _showMessage('${product.name} ajouté à la liste de courses.');
      }
    } catch (e) {
      if (mounted) _showMessage('$e');
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(activeGroupProvider.select((g) => g?.id));
    final name = widget.product.name.toLowerCase();
    final isInList =
        groupId != null &&
        ref.watch(
          shoppingListProvider(groupId).select(
            (list) =>
                list.value?.items.any((i) => i.name.toLowerCase() == name) ??
                false,
          ),
        );
    final onPressed = isInList || _isAdding ? null : () => _add(groupId);
    final icon = isInList ? Icons.check_circle : Icons.add_shopping_cart;
    final label = widget.label;

    if (label != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(isInList ? 'Dans la liste' : label),
      );
    }

    return IconButton(
      onPressed: onPressed,
      tooltip: isInList ? 'Dans la liste de courses' : 'Ajouter à la liste',
      icon: Icon(icon, color: isInList ? AppColors.brand : null),
    );
  }
}
