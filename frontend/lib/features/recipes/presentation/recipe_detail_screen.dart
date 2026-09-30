import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe.dart';
import 'recipes_controller.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(recipesControllerProvider.notifier).delete(recipe.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        // Réservé au créateur (403 sinon) — voir CreateRecipeProcessor/security
        // côté backend. Pas de moyen simple de savoir côté client si on est
        // l'auteur avant de tenter, donc on laisse le backend trancher.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Pour ${recipe.referenceServings} personne(s)',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Macro(label: 'Kcal', value: recipe.totalCalories),
                  _Macro(label: 'Protéines', value: recipe.totalProteins),
                  _Macro(label: 'Glucides', value: recipe.totalCarbs),
                  _Macro(label: 'Lipides', value: recipe.totalFats),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Ingrédients', style: Theme.of(context).textTheme.titleMedium),
          for (final ingredient in recipe.ingredients)
            ListTile(
              leading: const Icon(Icons.circle, size: 8),
              title: Text(ingredient.name),
              trailing: Text('${ingredient.quantity} ${ingredient.unit}'),
            ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toStringAsFixed(0), style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
