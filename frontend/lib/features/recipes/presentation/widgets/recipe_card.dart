import 'package:flutter/material.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/recipes/domain/recipe.dart';
import 'package:keepmydiet/features/recipes/presentation/widgets/macro_bar.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  static const _styles = [
    _RecipeStyle(
      Icons.ramen_dining_outlined,
      AppColors.recipeBg,
      AppColors.recipeIcon,
    ),
    _RecipeStyle(Icons.eco_outlined, AppColors.brandLight, AppColors.brandDark),
    _RecipeStyle(Icons.egg_outlined, AppColors.carbsBg, AppColors.carbsIcon),
    _RecipeStyle(
      Icons.set_meal_outlined,
      AppColors.waterBg,
      AppColors.waterIcon,
    ),
    _RecipeStyle(
      Icons.bakery_dining_outlined,
      AppColors.fatBg,
      AppColors.fatIcon,
    ),
  ];

  String get _details {
    final kcal = recipe.caloriesPerServing.toStringAsFixed(0);
    final minutes = recipe.totalMinutes;
    final duration = minutes > 0 ? ' · $minutes min' : '';
    return '$kcal kcal / pers. · ${recipe.referenceServings} pers.$duration';
  }

  @override
  Widget build(BuildContext context) {
    final style = _styles[recipe.id % _styles.length];

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(14),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      leading: IconBadge(
        icon: style.icon,
        background: style.background,
        foreground: style.foreground,
        size: 64,
        radius: AppRadius.md,
      ),
      title: Text(
        recipe.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            _details,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          MacroBar(
            proteins: recipe.totalProteins,
            carbs: recipe.totalCarbs,
            fats: recipe.totalFats,
          ),
        ],
      ),
    );
  }
}

class _RecipeStyle {
  const _RecipeStyle(this.icon, this.background, this.foreground);

  final IconData icon;
  final Color background;
  final Color foreground;
}
