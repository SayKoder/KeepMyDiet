import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../data/meal_plan_api_client.dart';
import '../domain/meal_plan_entry.dart';
import '../domain/meal_plan_failure.dart';
import '../domain/meal_type.dart';

/// Début (lundi minuit, normalisé) de la semaine actuellement affichée —
/// séparé du reste de l'état pour que `mealPlanEntriesProvider` (family) sache
/// quand refaire une requête sans redéclencher un fetch à chaque frappe.
class MealPlanWeekStartNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _startOfWeek(DateTime.now());

  void previousWeek() => state = state.subtract(const Duration(days: 7));

  void nextWeek() => state = state.add(const Duration(days: 7));
}

DateTime _startOfWeek(DateTime date) {
  final midnight = DateTime(date.year, date.month, date.day);
  // weekday : 1 = lundi ... 7 = dimanche (norme Dart).
  return midnight.subtract(Duration(days: midnight.weekday - 1));
}

final mealPlanWeekStartProvider =
    NotifierProvider<MealPlanWeekStartNotifier, DateTime>(MealPlanWeekStartNotifier.new);

/// Groupe dont on affiche le planning. Propre à cette feature (pas de
/// concept de "groupe actif" partagé ailleurs dans l'app pour l'instant) :
/// `null` tant que l'utilisateur n'a pas choisi, `MealPlanScreen` retombe
/// alors sur le premier groupe de la liste.
class MealPlanSelectedGroupNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int groupId) => state = groupId;
}

final mealPlanSelectedGroupProvider =
    NotifierProvider<MealPlanSelectedGroupNotifier, int?>(MealPlanSelectedGroupNotifier.new);

/// Scopé par groupe (clé family) ET par semaine affichée (lue à
/// l'intérieur) : changer l'un ou l'autre déclenche naturellement un
/// nouveau fetch.
final mealPlanEntriesProvider = FutureProvider.family<List<MealPlanEntry>, int>((ref, groupId) {
  final weekStart = ref.watch(mealPlanWeekStartProvider);

  return ref.read(mealPlanApiClientProvider).fetchEntries(
        groupId: groupId,
        from: weekStart,
        to: weekStart.add(const Duration(days: 6)),
      );
});

final mealPlanControllerProvider = Provider<MealPlanController>((ref) => MealPlanController(ref));

class MealPlanController {
  MealPlanController(this._ref);

  final Ref _ref;

  Future<void> addEntry({
    required int groupId,
    required DateTime date,
    required MealType mealType,
    required int recipeId,
    required int servings,
  }) async {
    try {
      await _ref.read(mealPlanApiClientProvider).createEntry(
            groupId: groupId,
            date: date,
            mealType: mealType,
            recipeId: recipeId,
            servings: servings,
          );
    } on DioException catch (e) {
      throw MealPlanFailure(extractErrorMessage(e));
    }

    _ref.invalidate(mealPlanEntriesProvider(groupId));
  }

  Future<void> deleteEntry({required int groupId, required int entryId}) async {
    try {
      await _ref.read(mealPlanApiClientProvider).deleteEntry(entryId);
    } on DioException catch (e) {
      throw MealPlanFailure(extractErrorMessage(e));
    }

    _ref.invalidate(mealPlanEntriesProvider(groupId));
  }

  /// Génère/complète la liste de courses active du groupe à partir de la
  /// semaine actuellement affichée (pas forcément les 7 jours : juste ce que
  /// `mealPlanWeekStartProvider` pointe en ce moment).
  Future<void> generateShoppingListFromVisibleWeek(int groupId) async {
    final weekStart = _ref.read(mealPlanWeekStartProvider);

    try {
      await _ref.read(mealPlanApiClientProvider).generateShoppingListFromPlan(
            groupId: groupId,
            from: weekStart,
            to: weekStart.add(const Duration(days: 6)),
          );
    } on DioException catch (e) {
      throw MealPlanFailure(extractErrorMessage(e));
    }
  }
}
