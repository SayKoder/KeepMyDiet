import 'package:flutter/material.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/fridge/domain/fridge_item.dart';
import 'package:keepmydiet/features/fridge/presentation/widgets/expiry_chip.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class FridgeItemCard extends StatelessWidget {
  const FridgeItemCard({super.key, required this.item});

  final FridgeItem item;

  static const _palettes = [
    (AppColors.proteinBg, AppColors.proteinIcon),
    (AppColors.waterBg, AppColors.waterIcon),
    (AppColors.brandLight, AppColors.brandDark),
    (AppColors.carbsBg, AppColors.carbsIcon),
    (AppColors.fatBg, AppColors.fatIcon),
  ];

  @override
  Widget build(BuildContext context) {
    final name = item.foodReference.name;
    final (background, foreground) = _palettes[item.id % _palettes.length];
    final quantity = item.quantity.toStringAsFixed(0);
    final kcal = item.foodReference.caloriesPer100g.toStringAsFixed(0);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      leading: LetterAvatar(
        text: name,
        background: background,
        foreground: foreground,
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        '$quantity ${item.unit} · $kcal kcal/100 g',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: ExpiryChip(date: item.expirationDate),
      onTap: () => showFoodDetailSheet(
        context,
        name: name,
        calories: item.foodReference.caloriesPer100g,
        proteins: item.foodReference.proteinsPer100g,
        carbs: item.foodReference.carbsPer100g,
        fats: item.foodReference.fatsPer100g,
        subtitle: '${item.storageLocation.label} · $quantity ${item.unit}',
      ),
    );
  }
}
