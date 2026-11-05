import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/recipes/domain/recipe.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_ingredient.dart';
import 'package:keepmydiet/features/recipes/presentation/recipes_controller.dart';
import 'package:keepmydiet/features/recipes/presentation/widgets/recipe_macros_card.dart';
import 'package:keepmydiet/features/recipes/presentation/widgets/recipe_step_card.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  // Seul l'auteur peut supprimer : le backend renvoie 403 sinon.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette recette ?'),
        content: Text('« ${recipe.name} » sera supprimée définitivement.'),
        actions: [
          DialogActionButtons(
            cancelLabel: 'Annuler',
            onCancel: () => Navigator.of(dialogContext).pop(false),
            confirmLabel: 'Supprimer',
            onConfirm: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(recipesControllerProvider.notifier).delete(recipe.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionTitle = Theme.of(context).textTheme.titleLarge;
    final count = recipe.ingredients.length;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(recipe: recipe, onDelete: () => _delete(context, ref)),
          // La carte remonte sur l'en-tête coloré.
          Transform.translate(
            offset: const Offset(0, -36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: RecipeMacrosCard(recipe: recipe),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Ingrédients', style: sectionTitle)),
                    Text(
                      '$count élément${count > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _IngredientsCard(ingredients: recipe.ingredients),
                if (recipe.steps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Préparation', style: sectionTitle),
                  for (var i = 0; i < recipe.steps.length; i++)
                    RecipeStepCard(number: i + 1, step: recipe.steps[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.recipe, required this.onDelete});

  final Recipe recipe;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final minutes = recipe.totalMinutes;

    return Container(
      decoration: const BoxDecoration(color: AppColors.recipeBg),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: -70,
            bottom: -60,
            child: CircleAvatar(
              radius: 110,
              backgroundColor: AppColors.calories.withValues(alpha: 0.18),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Row(
                    children: [
                      const RoundBackButton(),
                      const Spacer(),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.errorText,
                        tooltip: 'Supprimer',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: const Size(44, 44),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    recipe.name,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: const Color(0xFF3B1A0C)),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      Pill(
                        label:
                            '${recipe.referenceServings} '
                            'personne${recipe.referenceServings > 1 ? 's' : ''}',
                        background: Colors.white,
                        foreground: AppColors.ink,
                      ),
                      if (minutes > 0)
                        Pill(
                          label: '$minutes min',
                          background: Colors.white,
                          foreground: AppColors.ink,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsCard extends StatelessWidget {
  const _IngredientsCard({required this.ingredients});

  final List<RecipeIngredient> ingredients;

  String _quantity(RecipeIngredient ingredient) {
    final value = ingredient.quantity;
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
    return '$text ${ingredient.unit}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: ListTile.divideTiles(
          context: context,
          color: AppColors.border,
          tiles: [
            for (final ingredient in ingredients)
              ListTile(
                leading: const CircleAvatar(
                  radius: 5,
                  backgroundColor: AppColors.brand,
                ),
                minLeadingWidth: 10,
                title: Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  _quantity(ingredient),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ).toList(),
      ),
    );
  }
}
