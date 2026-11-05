import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/features/home/presentation/journal_date_controller.dart';
import 'package:keepmydiet/features/home/presentation/journal_quick_add_sheet.dart';
import 'package:keepmydiet/features/home/presentation/widgets/meal_prompt_card.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry_status.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_type.dart';
import 'package:keepmydiet/features/meal_plan/presentation/add_meal_plan_entry_screen.dart';
import 'package:keepmydiet/features/meal_plan/presentation/meal_plan_controller.dart';
import 'package:keepmydiet/features/nutrition/presentation/daily_nutrition_log_controller.dart';
import 'package:keepmydiet/shared/api_client.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

Future<void> showAddMealSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const AddMealSheet(),
  );
}

// Chaque action ferme la feuille seulement à la fin : la fermer avant
// démonterait `context` et le travail qui suit ne s'exécuterait jamais.
class AddMealSheet extends ConsumerWidget {
  const AddMealSheet({super.key});

  static const _mealIcons = {
    MealType.breakfast: Icons.free_breakfast_outlined,
    MealType.lunch: Icons.lunch_dining_outlined,
    MealType.dinner: Icons.dinner_dining_outlined,
  };

  Future<void> _addSnack(BuildContext context, WidgetRef ref) async {
    final groupId = ref.read(activeGroupProvider)?.id;
    final result = await showJournalQuickAddSheet(context, groupId: groupId);
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(dailyNutritionLogControllerProvider.notifier)
          .add(
            deltaKcal: result.kcal.round(),
            deltaProteinG: result.proteinG,
            deltaCarbG: result.carbG,
            deltaFatG: result.fatG,
          );
    } on DioException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }

    if (context.mounted) Navigator.of(context).pop();
  }

  // Ici l'utilisateur déclare ce qu'il a mangé : le créneau est créé (ou
  // remplacé) puis marqué "mangé" directement.
  Future<void> _addMeal(
    BuildContext context,
    WidgetRef ref,
    MealType mealType,
    MealPlanEntry? existing,
  ) async {
    final groupId = ref.read(activeGroupProvider)?.id;
    if (groupId == null) return;

    if (existing != null) {
      final replace = await _confirmReplace(context, mealType, existing);
      if (!replace || !context.mounted) return;
    }

    final entry = await Navigator.of(context).push<MealPlanEntry>(
      MaterialPageRoute(
        builder: (_) => AddMealPlanEntryScreen(
          groupId: groupId,
          date: ref.read(journalDateProvider),
          mealType: mealType,
          existingEntryId: existing?.id,
        ),
      ),
    );
    if (entry == null || !context.mounted) return;

    try {
      await ref
          .read(mealPlanControllerProvider)
          .respondToEntry(entryId: entry.id, status: MealPlanEntryStatus.eaten);
    } on DioException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }

    if (context.mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmReplace(
    BuildContext context,
    MealType mealType,
    MealPlanEntry existing,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${mealType.label} déjà prévu'),
        content: Text(
          '${existing.recipe.name} est déjà prévu pour ce créneau. Le remplacer ?',
        ),
        actions: [
          DialogActionButtons(
            cancelLabel: 'Annuler',
            onCancel: () => Navigator.of(dialogContext).pop(false),
            confirmLabel: 'Remplacer',
            onConfirm: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final entries = activeGroup == null
        ? const <MealPlanEntry>[]
        : ref.watch(mealPlanEntriesForDateProvider(activeGroup.id)).value ??
              const <MealPlanEntry>[];
    final answeredIds = {
      for (final log in ref.watch(mealPlanEntryLogsProvider).value ?? const [])
        log.mealPlanEntryId,
    };
    final pendingEntries = entries
        .where((entry) => !answeredIds.contains(entry.id))
        .toList();

    MealPlanEntry? existingFor(MealType type) =>
        entries.where((entry) => entry.mealType == type).firstOrNull;

    final sectionStyle = Theme.of(context).textTheme.labelSmall;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              'Ajouter un repas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('REPAS DU JOUR', style: sectionStyle),
            for (final MapEntry(key: type, value: icon) in _mealIcons.entries)
              _ChooserTile(
                icon: icon,
                label: type.label,
                onTap: () => _addMeal(context, ref, type, existingFor(type)),
              ),
            if (pendingEntries.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('REPAS PLANIFIÉS', style: sectionStyle),
              for (final entry in pendingEntries) MealPromptCard(entry: entry),
            ],
            const SizedBox(height: 10),
            _ChooserTile(
              icon: Icons.fastfood_outlined,
              label: 'Petite faim',
              background: AppColors.brandLight,
              foreground: AppColors.brandDark,
              onTap: () => _addSnack(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChooserTile extends StatelessWidget {
  const _ChooserTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.background = AppColors.fieldFill,
    this.foreground = AppColors.ink,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: background,
      iconColor: foreground,
      textColor: foreground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
