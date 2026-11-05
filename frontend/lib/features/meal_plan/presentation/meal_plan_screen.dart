import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/date_labels.dart';
import '../../../shared/widgets/async_value_ui.dart';
import '../../../shared/widgets/group_switcher_menu_button.dart';
import '../../fridge/presentation/fridge_controller.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_controller.dart';
import '../domain/missing_ingredient.dart';
import 'meal_plan_controller.dart';
import 'widgets/day_card.dart';
import 'widgets/missing_ingredients_sheet.dart';

enum _MenuAction { missing, generate }

class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});

  Group? _selectedGroup(List<Group> groups, int? selectedId) =>
      groups.where((g) => g.id == selectedId).firstOrNull ?? groups.firstOrNull;

  String _weekLabel(DateTime weekStart) {
    final format = DateFormat('d MMM', 'fr_FR');
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${format.format(weekStart)} — ${format.format(weekEnd)}';
  }

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
        _showMessage(
          context,
          'Liste de courses mise à jour avec ce qui manque.',
        );
      }
    } catch (e) {
      if (context.mounted) _showMessage(context, '$e');
    }
  }

  // `.future` : le frigo n'est pas affiché ici, il peut ne pas être chargé.
  Future<void> _showMissingIngredients(
    BuildContext context,
    WidgetRef ref,
    int groupId,
  ) async {
    final entries = await ref.read(mealPlanEntriesProvider(groupId).future);
    final fridgeItems = await ref.read(fridgeItemsProvider(groupId).future);
    if (!context.mounted) return;
    await showMissingIngredientsSheet(
      context,
      computeMissingIngredients(entries, fridgeItems),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsControllerProvider).value ?? [];
    final group = _selectedGroup(
      groups,
      ref.watch(mealPlanSelectedGroupProvider),
    );
    final weekStart = ref.watch(mealPlanWeekStartProvider);
    final week = ref.read(mealPlanWeekStartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
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
                  onPressed: week.previousWeek,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Semaine précédente',
                ),
                IconButton(
                  onPressed: week.nextWeek,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Semaine suivante',
                ),
                PopupMenuButton<_MenuAction>(
                  onSelected: (action) => switch (action) {
                    _MenuAction.missing => _showMissingIngredients(
                      context,
                      ref,
                      group.id,
                    ),
                    _MenuAction.generate => _generateShoppingList(
                      context,
                      ref,
                      group.id,
                    ),
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _MenuAction.missing,
                      child: Text('Ce qui manque'),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.generate,
                      child: Text('Générer la liste de courses'),
                    ),
                  ],
                ),
              ],
      ),
      body: group == null
          ? const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Aucun groupe',
              message: 'Rejoins ou crée un groupe pour planifier des repas.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _weekLabel(weekStart),
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
}

class _WeekList extends ConsumerWidget {
  const _WeekList({required this.groupId, required this.weekStart});

  final int groupId;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(mealPlanEntriesProvider(groupId));
    final days = [for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i))];

    return entriesAsync.toWidget(
      onRetry: () => ref.invalidate(mealPlanEntriesProvider(groupId)),
      data: (entries) => RefreshIndicator(
        onRefresh: () => ref.refresh(mealPlanEntriesProvider(groupId).future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final date in days)
              DayCard(
                groupId: groupId,
                date: date,
                entries: entries.where((e) => isSameDay(e.date, date)).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
