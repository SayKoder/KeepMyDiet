import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/async_value_ui.dart';
import '../domain/recipe_suggestion.dart';
import 'recipe_suggestions_controller.dart';

class RecipeSuggestionsScreen extends ConsumerWidget {
  const RecipeSuggestionsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final int groupId;
  final String groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(recipeSuggestionsProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: Text('Suggestions — $groupName')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(recipeSuggestionsProvider(groupId).future),
        child: suggestionsAsync.toWidget(
          onRetry: () => ref.invalidate(recipeSuggestionsProvider(groupId)),
          isEmpty: (suggestions) => suggestions.isEmpty,
          empty: const EmptyState(
            icon: Icons.lightbulb_outline,
            title: 'Aucune suggestion',
            message: 'Aucune recette dans le pool pour le moment.',
          ),
          data: (suggestions) => ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: suggestions.length,
            itemBuilder: (context, index) =>
                _SuggestionCard(suggestion: suggestions[index]),
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});

  final RecipeSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soonest = suggestion.soonestExpirationDate;
    // Même seuil que FridgeItem.isExpiringSoon (anti-gaspillage) — pas
    // d'import croisé pour un simple seuil, dupliqué volontairement.
    final isUrgent =
        soonest != null && soonest.difference(DateTime.now()).inDays < 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    '${suggestion.matchedIngredientsCount}/${suggestion.totalIngredientsCount}',
                  ),
                  backgroundColor: suggestion.isFullyAvailable
                      ? theme.colorScheme.primaryContainer
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${suggestion.caloriesPerServing.toStringAsFixed(0)} kcal / portion'
              ' — pour ${suggestion.referenceServings} pers.',
              style: theme.textTheme.bodySmall,
            ),
            if (soonest != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: isUrgent ? theme.colorScheme.error : null,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Utilise un ingrédient qui périme le ${soonest.day}/${soonest.month}/${soonest.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUrgent
                          ? theme.colorScheme.error
                          : theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
            if (suggestion.missingIngredientNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestion.missingIngredientNames
                    .map(
                      (name) => Chip(
                        label: Text(name, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
