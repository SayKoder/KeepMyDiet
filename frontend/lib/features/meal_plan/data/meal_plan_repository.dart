import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/meal_plan/data/meal_plan_api_client.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry_log.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_plan_entry_status.dart';
import 'package:keepmydiet/features/meal_plan/domain/meal_type.dart';
import 'package:keepmydiet/shared/local_database.dart';
import 'package:keepmydiet/shared/network_first.dart';

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepository(
    ref.watch(mealPlanApiClientProvider),
    ref.watch(localDatabaseProvider),
  );
});

class MealPlanRepository {
  MealPlanRepository(this._api, this._database);

  final MealPlanApiClient _api;
  final LocalDatabase _database;

  Future<List<MealPlanEntry>> fetchEntries({
    required int groupId,
    required DateTime from,
    required DateTime to,
  }) => networkFirst(
    _database,
    key: 'meal_plan_${groupId}_${_day(from)}_${_day(to)}',
    fetch: () => _api.fetchEntries(groupId: groupId, from: from, to: to),
    toJson: (entries) => [for (final entry in entries) entry.toJson()],
    fromJson: (json) => [
      for (final entry in json as List)
        MealPlanEntry.fromJson(entry as Map<String, dynamic>),
    ],
  );

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

  Future<List<MealPlanEntryLog>> fetchEntryLogs(DateTime date) => networkFirst(
    _database,
    key: 'meal_plan_logs_${_day(date)}',
    fetch: () => _api.fetchEntryLogs(date),
    toJson: (logs) => [for (final log in logs) log.toJson()],
    fromJson: (json) => [
      for (final log in json as List)
        MealPlanEntryLog.fromJson(log as Map<String, dynamic>),
    ],
  );

  String _day(DateTime date) => date.toIso8601String().substring(0, 10);
}
