import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/meal_plan/data/meal_plan_api_client.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry_log.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry_status.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_type.dart';

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepository(ref.watch(mealPlanApiClientProvider));
});

class MealPlanRepository {
  MealPlanRepository(this._api);

  final MealPlanApiClient _api;

  Future<List<MealPlanEntry>> fetchEntries({
    required int groupId,
    required DateTime from,
    required DateTime to,
  }) => _api.fetchEntries(groupId: groupId, from: from, to: to);

  Future<MealPlanEntry> createEntry({
    required int groupId,
    required DateTime date,
    required MealType mealType,
    required int recipeId,
    required int servings,
  }) => _api.createEntry(
    groupId: groupId,
    date: date,
    mealType: mealType,
    recipeId: recipeId,
    servings: servings,
  );

  Future<MealPlanEntry> updateEntry({
    required int entryId,
    required int recipeId,
    required int servings,
  }) => _api.updateEntry(
    entryId: entryId,
    recipeId: recipeId,
    servings: servings,
  );

  Future<void> deleteEntry(int id) => _api.deleteEntry(id);

  Future<void> generateShoppingListFromPlan({
    required int groupId,
    required DateTime from,
    required DateTime to,
  }) => _api.generateShoppingListFromPlan(groupId: groupId, from: from, to: to);

  Future<MealPlanEntryLog> submitMealPlanEntryLog({
    required int entryId,
    required MealPlanEntryStatus status,
    String? replacementDescription,
    double? replacementCalories,
    double? replacementProteinG,
    double? replacementCarbG,
    double? replacementFatG,
  }) => _api.submitMealPlanEntryLog(
    entryId: entryId,
    status: status,
    replacementDescription: replacementDescription,
    replacementCalories: replacementCalories,
    replacementProteinG: replacementProteinG,
    replacementCarbG: replacementCarbG,
    replacementFatG: replacementFatG,
  );

  Future<List<MealPlanEntryLog>> fetchEntryLogs(DateTime date) =>
      _api.fetchEntryLogs(date);
}
