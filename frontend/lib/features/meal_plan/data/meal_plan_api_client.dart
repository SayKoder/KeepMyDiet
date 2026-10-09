import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/meal_plan_entry_log.dart';
import '../domain/meal_plan_entry_status.dart';
import '../../../shared/api_client.dart';
import '../domain/meal_plan_entry.dart';
import '../domain/meal_type.dart';

final mealPlanApiClientProvider = Provider<MealPlanApiClient>((ref) {
  return MealPlanApiClient(ref.watch(dioProvider));
});

class MealPlanApiClient {
  MealPlanApiClient(this._dio);

  final Dio _dio;
  static final _ldJson = Options(contentType: 'application/ld+json');

  String _iso(DateTime date) => date.toIso8601String().split('T').first;

  Future<List<MealPlanEntry>> fetchEntries({
    required int groupId,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/meal_plan_entries',
      queryParameters: {'from': _iso(from), 'to': _iso(to)},
    );
    final members = response.data!['member'] as List<dynamic>;

    return members.map((e) => MealPlanEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MealPlanEntry> createEntry({
    required int groupId,
    required DateTime date,
    required MealType mealType,
    required int recipeId,
    required int servings,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/meal_plan_entries',
      data: {
        'group': '/api/groups/$groupId',
        'date': _iso(date),
        'mealType': mealType.toJson(),
        'recipe': '/api/recipes/$recipeId',
        'servings': servings,
      },
      options: _ldJson,
    );

    return MealPlanEntry.fromJson(response.data!);
  }

  /// Remplace la recette d'un créneau déjà prévu (confirmation "Remplacer ?"
  /// sur l'Accueil) plutôt que supprimer + recréer un nouvel id.
  Future<MealPlanEntry> updateEntry({
    required int entryId,
    required int recipeId,
    required int servings,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/meal_plan_entries/$entryId',
      data: {'recipe': '/api/recipes/$recipeId', 'servings': servings},
      options: Options(contentType: 'application/merge-patch+json'),
    );

    return MealPlanEntry.fromJson(response.data!);
  }

  Future<void> deleteEntry(int id) async {
    await _dio.delete<void>('/meal_plan_entries/$id');
  }

  /// Fusionne (par nom+unité) et soustrait le stock actuel, contrairement à
  /// la génération "classique" depuis une sélection manuelle de recettes
  /// (voir GenerateShoppingListFromMealPlanProcessor côté backend).
  Future<void> generateShoppingListFromPlan({
    required int groupId,
    required DateTime from,
    required DateTime to,
  }) async {
    await _dio.post<void>(
      '/groups/$groupId/shopping_lists/generate_from_plan',
      data: {'from': _iso(from), 'to': _iso(to)},
      options: _ldJson,
    );
  }

    Future<MealPlanEntryLog> submitMealPlanEntryLog({
    required int entryId,
    required MealPlanEntryStatus status,
    String? replacementDescription,
    double? replacementCalories,
    double? replacementProteinG,
    double? replacementCarbG,
    double? replacementFatG,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/meal_plan_entry_logs',
      data: {
        'mealPlanEntry': '/api/meal_plan_entries/$entryId',
        'status': status.toJson(),
        'replacementDescription': replacementDescription,
        'replacementCalories': replacementCalories,
        'replacementProteinG': replacementProteinG,
        'replacementCarbG': replacementCarbG,
        'replacementFatG': replacementFatG,
      },
      options: _ldJson,
    );

    return MealPlanEntryLog.fromJson(response.data!);
  }

  Future<List<MealPlanEntryLog>> fetchEntryLogs(DateTime date) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/meal_plan_entry_logs',
      queryParameters: {'date': _iso(date)},
    );
    final members = response.data!['member'] as List<dynamic>;

    return members.map((e) => MealPlanEntryLog.fromJson(e as Map<String, dynamic>)).toList();
  }

}
