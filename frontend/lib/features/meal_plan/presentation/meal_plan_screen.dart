import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/async_value_ui.dart';
import '../../../shared/group_switcher_menu_button.dart';
import '../../fridge/presentation/fridge_controller.dart';
import '../../groups/presentation/groups_controller.dart';
import '../domain/meal_plan_entry.dart';
import '../domain/meal_type.dart';
import '../domain/missing_ingredient.dart';
import 'add_meal_plan_entry_screen.dart';
import 'meal_plan_controller.dart';

enum _MealPlanMenuAction { missing, generate }

class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsControllerProvider).value ?? [];
    final selectedId = ref.watch(mealPlanSelectedGroupProvider);
    final group = selectedId != null && groups.any((g) => g.id == selectedId)
        ? groups.firstWhere((g) => g.id == selectedId)
        : (groups.isEmpty ? null : groups.first);

    final weekStart = ref.watch(mealPlanWeekStartProvider);
    final weekLabel =
        '${DateFormat('d MMM', 'fr_FR').format(weekStart)} — '
        '${DateFormat('d MMM', 'fr_FR').format(weekStart.add(const Duration(days: 6)))}';

    return Scaffold(
      appBar: AppBar(
        // Juste "Planning" dans l'AppBar (pas la période) : avec le
        // sélecteur de groupe + les actions, un titre plus long se faisait
        // tronquer ("Pla...") — la période est affichée juste en dessous,
        // dans le corps, où il y a toute la largeur nécessaire.
        title: const Text('Planning'),
        actions: group == null
            ? null
            : [
                if (groups.length > 1)
                  GroupSwitcherMenuButton(
                    groups: groups,
                    onSelected: (selected) => ref
                        .read(mealPlanSelectedGroupProvider.notifier)
                        .select(selected.id),
                  ),
                IconButton(
                  onPressed: () => ref
                      .read(mealPlanWeekStartProvider.notifier)
                      .previousWeek(),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Semaine précédente',
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(mealPlanWeekStartProvider.notifier).nextWeek(),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Semaine suivante',
                ),
                // Regroupées dans un menu (pas 2 icônes de plus) : avec le
                // sélecteur de groupe et les flèches semaine, ça faisait
                // déjà tronquer le titre même raccourci à "Planning".
                PopupMenuButton<_MealPlanMenuAction>(
                  onSelected: (action) => switch (action) {
                    _MealPlanMenuAction.missing => _showMissingIngredients(
                      context,
                      ref,
                      group.id,
                      weekStart,
                    ),
                    _MealPlanMenuAction.generate => _generateShoppingList(
                      context,
                      ref,
                      group.id,
                    ),
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _MealPlanMenuAction.missing,
                      child: Text('Ce qui manque'),
                    ),
                    PopupMenuItem(
                      value: _MealPlanMenuAction.generate,
                      child: Text('Générer la liste de courses'),
                    ),
                  ],
                ),
              ],
      ),
      body: group == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "Rejoins ou crée un groupe pour planifier des repas.",
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    weekLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: _WeekList(groupId: group.id, weekStart: weekStart),
                ),
              ],
            ),
    );
  }

  Future<void> _generateShoppingList(
    BuildContext context,
    WidgetRef ref,
    int groupId,
  ) async {
    try {
      await ref
          .read(mealPlanControllerProvider)
          .generateShoppingListFromVisibleWeek(groupId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liste de courses mise à jour avec ce qui manque.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _showMissingIngredients(
    BuildContext context,
    WidgetRef ref,
    int groupId,
    DateTime weekStart,
  ) async {
    // `.future` (pas `.value`) : le frigo n'est jamais affiché ailleurs sur
    // cet écran, donc `fridgeItemsProvider` peut ne pas encore avoir
    // résolu — un `.value` lu avant la fin du premier fetch vaut `null` et
    // retombait sur un stock vide, faisant passer tout le monde pour
    // "manquant" (bug constaté : 37,5g de tomate déjà couverts par 100g en
    // stock affichés comme entièrement manquants).
    final entries = await ref.read(mealPlanEntriesProvider(groupId).future);
    final fridgeItems = await ref.read(fridgeItemsProvider(groupId).future);
    final missing = computeMissingIngredients(entries, fridgeItems);

    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ce qui manque cette semaine",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (missing.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Tout est déjà au frigo/placard pour les repas prévus.",
                  ),
                )
              else
                for (final item in missing)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.shopping_basket_outlined),
                    title: Text(item.name),
                    trailing: Text(
                      '${item.missingQuantity.toStringAsFixed(0)} ${item.unit}',
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekList extends ConsumerWidget {
  const _WeekList({required this.groupId, required this.weekStart});

  final int groupId;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(mealPlanEntriesProvider(groupId));

    return entriesAsync.toWidget(
      data: (entries) => RefreshIndicator(
        onRefresh: () => ref.refresh(mealPlanEntriesProvider(groupId).future),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 7,
          itemBuilder: (context, index) {
            final date = weekStart.add(Duration(days: index));
            final dayEntries = entries
                .where((e) => _isSameDay(e.date, date))
                .toList();

            return _DayCard(groupId: groupId, date: date, entries: dayEntries);
          },
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DayCard extends ConsumerWidget {
  const _DayCard({
    required this.groupId,
    required this.date,
    required this.entries,
  });

  final int groupId;
  final DateTime date;
  final List<MealPlanEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCalories = entries.fold<double>(0, (sum, e) => sum + e.calories);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _capitalize(DateFormat('EEEE d MMMM', 'fr_FR').format(date)),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (totalCalories > 0)
                  Text(
                    '${totalCalories.toStringAsFixed(0)} kcal',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const Divider(),
            for (final mealType in MealType.values)
              _MealTypeRow(
                groupId: groupId,
                date: date,
                mealType: mealType,
                entries: entries.where((e) => e.mealType == mealType).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _MealTypeRow extends ConsumerWidget {
  const _MealTypeRow({
    required this.groupId,
    required this.date,
    required this.mealType,
    required this.entries,
  });

  final int groupId;
  final DateTime date;
  final MealType mealType;
  final List<MealPlanEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              mealType.label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Text('—', style: Theme.of(context).textTheme.bodySmall)
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final entry in entries)
                        InputChip(
                          label: Text(
                            entry.servings > 1
                                ? '${entry.recipe.name} ×${entry.servings}'
                                : entry.recipe.name,
                          ),
                          onDeleted: () => _delete(context, ref, entry.id),
                        ),
                    ],
                  ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddMealPlanEntryScreen(
                  groupId: groupId,
                  date: date,
                  mealType: mealType,
                ),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Ajouter',
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int entryId) async {
    try {
      await ref
          .read(mealPlanControllerProvider)
          .deleteEntry(groupId: groupId, entryId: entryId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
