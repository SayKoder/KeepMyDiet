import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/meal_plan_entry.dart';
import '../domain/meal_type.dart';
import 'meal_plan_controller.dart';
import 'widgets/existing_recipe_tab.dart';
import 'widgets/quick_add_tab.dart';

class AddMealPlanEntryScreen extends ConsumerWidget {
  const AddMealPlanEntryScreen({
    super.key,
    required this.groupId,
    required this.date,
    required this.mealType,
    this.existingEntryId,
  });

  final int groupId;
  final DateTime date;
  final MealType mealType;

  // Renseigné quand on remplace un créneau existant (PATCH au lieu de POST).
  final int? existingEntryId;

  Future<MealPlanEntry> _saveEntry(
    WidgetRef ref, {
    required int recipeId,
    required int servings,
  }) {
    final controller = ref.read(mealPlanControllerProvider);
    final entryId = existingEntryId;

    if (entryId == null) {
      return controller.addEntry(
        groupId: groupId,
        date: date,
        mealType: mealType,
        recipeId: recipeId,
        servings: servings,
      );
    }
    return controller.updateEntry(
      groupId: groupId,
      entryId: entryId,
      recipeId: recipeId,
      servings: servings,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = '${mealType.label} — ${date.day}/${date.month}';
    Future<MealPlanEntry> save({
      required int recipeId,
      required int servings,
    }) => _saveEntry(ref, recipeId: recipeId, servings: servings);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(existingEntryId == null ? slot : 'Remplacer : $slot'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recette existante'),
              Tab(text: 'Ajout rapide'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ExistingRecipeTab(saveEntry: save),
            QuickAddTab(
              defaultName: '${mealType.label} du ${date.day}/${date.month}',
              saveEntry: save,
            ),
          ],
        ),
      ),
    );
  }
}
