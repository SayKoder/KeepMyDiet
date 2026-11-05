import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/date_labels.dart';
import '../../domain/meal_plan_entry.dart';
import '../../domain/meal_type.dart';
import '../add_meal_plan_entry_screen.dart';
import '../meal_plan_controller.dart';

class DayCard extends StatelessWidget {
  const DayCard({
    super.key,
    required this.groupId,
    required this.date,
    required this.entries,
  });

  final int groupId;
  final DateTime date;
  final List<MealPlanEntry> entries;

  @override
  Widget build(BuildContext context) {
    final totalCalories = entries.fold<double>(0, (sum, e) => sum + e.calories);
    final textTheme = Theme.of(context).textTheme;

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
                Text(formatDayLabel(date), style: textTheme.titleMedium),
                if (totalCalories > 0)
                  Text(
                    '${totalCalories.toStringAsFixed(0)} kcal',
                    style: textTheme.bodySmall,
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

  String _label(MealPlanEntry entry) => entry.servings > 1
      ? '${entry.recipe.name} ×${entry.servings}'
      : entry.recipe.name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smallText = Theme.of(context).textTheme.bodySmall;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: SizedBox(
        width: 100,
        child: Text(mealType.label, style: smallText),
      ),
      title: entries.isEmpty
          ? Text('—', style: smallText)
          : Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final entry in entries)
                  InputChip(
                    label: Text(_label(entry)),
                    onDeleted: () => _delete(context, ref, entry.id),
                  ),
              ],
            ),
      trailing: IconButton(
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
        tooltip: 'Ajouter',
      ),
    );
  }
}
