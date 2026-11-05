import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/features/home/presentation/journal_quick_add_sheet.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry_status.dart';
import 'package:keepmydiet/features/meal_plan/presentation/meal_plan_controller.dart';
import 'package:keepmydiet/shared/api_client.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class MealPromptCard extends ConsumerWidget {
  const MealPromptCard({super.key, required this.entry});

  final MealPlanEntry entry;

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    MealPlanEntryStatus status,
  ) async {
    JournalQuickAddResult? replacement;

    if (status == MealPlanEntryStatus.replaced) {
      final groupId = ref.read(activeGroupProvider)?.id;
      replacement = await showJournalQuickAddSheet(context, groupId: groupId);
      if (replacement == null || !context.mounted) return;
    }

    try {
      await ref
          .read(mealPlanControllerProvider)
          .respondToEntry(
            entryId: entry.id,
            status: status,
            replacementDescription: replacement?.description,
            replacementCalories: replacement?.kcal,
            replacementProteinG: replacement?.proteinG,
            replacementCarbG: replacement?.carbG,
            replacementFatG: replacement?.fatG,
          );
    } on DioException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const answers = {
      MealPlanEntryStatus.eaten: 'Oui',
      MealPlanEntryStatus.skipped: 'Non',
      MealPlanEntryStatus.replaced: 'Autre chose',
    };

    return WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            '${entry.mealType.label} — ${entry.recipe.name} ?',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Row(
            spacing: 8,
            children: [
              for (final MapEntry(key: status, value: label) in answers.entries)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(context, ref, status),
                    child: Text(label),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
