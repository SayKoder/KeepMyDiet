import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}
