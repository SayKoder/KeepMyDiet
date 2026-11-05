import 'package:flutter/material.dart';

import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/shopping_list/domain/shopping_list_item.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class ShoppingItemGroup extends StatelessWidget {
  const ShoppingItemGroup({
    super.key,
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
  });

  final String title;
  final List<ShoppingListItem> items;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: ListTile.divideTiles(
              context: context,
              color: AppColors.border,
              tiles: [
                for (final item in items)
                  _ShoppingItemTile(
                    item: item,
                    checked: selectedIds.contains(item.id),
                    onTap: () => onToggle(item.id),
                  ),
              ],
            ).toList(),
          ),
        ),
      ],
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  const _ShoppingItemTile({
    required this.item,
    required this.checked,
    required this.onTap,
  });

  final ShoppingListItem item;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = checked ? AppColors.iconMuted : AppColors.ink;

    return ListTile(
      onTap: () => showFoodDetailSheet(
        context,
        name: item.name,
        calories: item.caloriesPer100g,
        proteins: item.proteinsPer100g,
        carbs: item.carbsPer100g,
        fats: item.fatsPer100g,
        subtitle: item.sourceRecipeName,
      ),
      leading: Checkbox(
        value: checked,
        onChanged: (_) => onTap(),
        shape: const CircleBorder(),
        activeColor: AppColors.brand,
      ),
      title: Text(
        item.name,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
          decoration: checked ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: Text(
        '${item.quantity.toStringAsFixed(0)} ${item.unit}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: checked ? AppColors.iconMuted : AppColors.textSecondary,
        ),
      ),
    );
  }
}
