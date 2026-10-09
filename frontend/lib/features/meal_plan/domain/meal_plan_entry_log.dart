import 'meal_plan_entry_status.dart';

class MealPlanEntryLog {
  const MealPlanEntryLog({
    required this.id,
    required this.mealPlanEntryId,
    required this.status,
    this.replacementDescription,
    this.replacementCalories,
    this.replacementProteinG,
    this.replacementCarbG,
    this.replacementFatG,
    required this.appliedCalories,
    required this.appliedProteinG,
    required this.appliedCarbG,
    required this.appliedFatG,
  });

  final int id;
  final int mealPlanEntryId;
  final MealPlanEntryStatus status;
  final String? replacementDescription;
  final double? replacementCalories;
  final double? replacementProteinG;
  final double? replacementCarbG;
  final double? replacementFatG;
  final int appliedCalories;
  final double appliedProteinG;
  final double appliedCarbG;
  final double appliedFatG;

  factory MealPlanEntryLog.fromJson(Map<String, dynamic> json) => MealPlanEntryLog(
        id: json['id'] as int,
        // `mealPlanEntry` arrive en IRI ("/api/meal_plan_entries/12") tant que
        // meal_plan_entry_log:read n'embarque pas l'objet complet — l'id suffit
        // pour retrouver l'entry déjà chargée côté client via fetchEntries.
        mealPlanEntryId: int.parse((json['mealPlanEntry'] as String).split('/').last),
        status: MealPlanEntryStatus.fromJson(json['status'] as String),
        replacementDescription: json['replacementDescription'] as String?,
        replacementCalories: (json['replacementCalories'] as num?)?.toDouble(),
        replacementProteinG: (json['replacementProteinG'] as num?)?.toDouble(),
        replacementCarbG: (json['replacementCarbG'] as num?)?.toDouble(),
        replacementFatG: (json['replacementFatG'] as num?)?.toDouble(),
        appliedCalories: json['appliedCalories'] as int,
        appliedProteinG: (json['appliedProteinG'] as num).toDouble(),
        appliedCarbG: (json['appliedCarbG'] as num).toDouble(),
        appliedFatG: (json['appliedFatG'] as num).toDouble(),
      );
}
