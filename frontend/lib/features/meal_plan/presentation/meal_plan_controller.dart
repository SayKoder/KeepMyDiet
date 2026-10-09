import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/journal_date_controller.dart';
import '../../nutrition/presentation/daily_nutrition_log_controller.dart';
import '../domain/meal_plan_entry_log.dart';
import '../domain/meal_plan_entry_status.dart';
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
    NotifierProvider<MealPlanWeekStartNotifier, DateTime>(
      MealPlanWeekStartNotifier.new,
    );

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
    NotifierProvider<MealPlanSelectedGroupNotifier, int?>(
      MealPlanSelectedGroupNotifier.new,
    );

/// Scopé par groupe (clé family) ET par semaine affichée (lue à
/// l'intérieur) : changer l'un ou l'autre déclenche naturellement un
/// nouveau fetch.
final mealPlanEntriesProvider = FutureProvider.family<List<MealPlanEntry>, int>(
  (ref, groupId) {
    final weekStart = ref.watch(mealPlanWeekStartProvider);

    return ref
        .read(mealPlanApiClientProvider)
        .fetchEntries(
          groupId: groupId,
          from: weekStart,
          to: weekStart.add(const Duration(days: 6)),
        );
  },
);

/// Les créneaux planifiés du jour actuellement affiché sur l'Accueil (pas la
/// semaine visible dans l'écran de planning, qui reste indépendante) — même
/// requête fetchEntries, bornée à un seul jour.
final mealPlanEntriesForDateProvider =
    FutureProvider.family<List<MealPlanEntry>, int>((ref, groupId) {
      final date = ref.watch(journalDateProvider);

      return ref
          .read(mealPlanApiClientProvider)
          .fetchEntries(groupId: groupId, from: date, to: date);
    });

/// Réponses (Oui/Non/Autre chose) de l'utilisateur courant pour le jour
/// affiché, tous groupes confondus.
final mealPlanEntryLogsProvider = FutureProvider<List<MealPlanEntryLog>>((ref) {
  final date = ref.watch(journalDateProvider);

  return ref.read(mealPlanApiClientProvider).fetchEntryLogs(date);
});

final mealPlanControllerProvider = Provider<MealPlanController>(
  (ref) => MealPlanController(ref),
);

class MealPlanController {
  MealPlanController(this._ref);

  final Ref _ref;

  Future<MealPlanEntry> addEntry({
    required int groupId,
    required DateTime date,
    required MealType mealType,
    required int recipeId,
    required int servings,
  }) async {
    final MealPlanEntry entry;
    try {
      entry = await _ref
          .read(mealPlanApiClientProvider)
          .createEntry(
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
    _ref.invalidate(mealPlanEntriesForDateProvider(groupId));

    return entry;
  }

  Future<MealPlanEntry> updateEntry({
    required int groupId,
    required int entryId,
    required int recipeId,
    required int servings,
  }) async {
    final MealPlanEntry entry;
    try {
      entry = await _ref
          .read(mealPlanApiClientProvider)
          .updateEntry(
            entryId: entryId,
            recipeId: recipeId,
            servings: servings,
          );
    } on DioException catch (e) {
      throw MealPlanFailure(extractErrorMessage(e));
    }

    _ref.invalidate(mealPlanEntriesProvider(groupId));
    _ref.invalidate(mealPlanEntriesForDateProvider(groupId));

    return entry;
  }

  Future<void> deleteEntry({required int groupId, required int entryId}) async {
    try {
      await _ref.read(mealPlanApiClientProvider).deleteEntry(entryId);
    } on DioException catch (e) {
      throw MealPlanFailure(extractErrorMessage(e));
    }

    _ref.invalidate(mealPlanEntriesProvider(groupId));
  }

  /// Répond au pop-up d'un créneau planifié ("as-tu mangé ça ?"). Met aussi à
  /// jour le journal du jour côté backend — on invalide les deux providers
  /// pour refléter le nouveau total à l'écran.
  Future<void> respondToEntry({
    required int entryId,
    required MealPlanEntryStatus status,
    String? replacementDescription,
    double? replacementCalories,
    double? replacementProteinG,
    double? replacementCarbG,
    double? replacementFatG,
  }) async {
    try {
      await _ref
          .read(mealPlanApiClientProvider)
          .submitMealPlanEntryLog(
            entryId: entryId,
            status: status,
            replacementDescription: replacementDescription,
            replacementCalories: replacementCalories,
            replacementProteinG: replacementProteinG,
            replacementCarbG: replacementCarbG,
            replacementFatG: replacementFatG,
          );
    } on DioException catch (e) {
      throw MealPlanFailure(extractErrorMessage(e));
    }

    _ref.invalidate(mealPlanEntryLogsProvider);
    _ref.invalidate(dailyNutritionLogControllerProvider);
  }

  /// Génère/complète la liste de courses active du groupe à partir de la
  /// semaine actuellement affichée (pas forcément les 7 jours : juste ce que
  /// `mealPlanWeekStartProvider` pointe en ce moment).
  Future<void> generateShoppingListFromVisibleWeek(int groupId) async {
    final weekStart = _ref.read(mealPlanWeekStartProvider);

    try {
      await _ref
          .read(mealPlanApiClientProvider)
          .generateShoppingListFromPlan(
            groupId: groupId,
            from: weekStart,
            to: weekStart.add(const Duration(days: 6)),
          );
    } on DioException catch (e) {
      throw MealPlanFailure(extractErrorMessage(e));
    }
  }
}
