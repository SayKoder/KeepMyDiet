import '../../recipes/domain/recipe.dart';
import 'meal_type.dart';

class MealPlanEntry {
  const MealPlanEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.recipe,
    required this.servings,
  });

  final int id;
  final DateTime date;
  final MealType mealType;
  final Recipe recipe;
  final int servings;

  /// Contribution réelle de ce créneau aux macros du jour : les totaux de
  /// `Recipe` sont pour `referenceServings`, pas pour `servings` prévus ici.
  double get ratio => servings / (recipe.referenceServings == 0 ? 1 : recipe.referenceServings);

  double get calories => recipe.totalCalories * ratio;
  double get proteins => recipe.totalProteins * ratio;
  double get carbs => recipe.totalCarbs * ratio;
  double get fats => recipe.totalFats * ratio;

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        id: json['id'] as int,
        date: DateTime.parse(json['date'] as String),
        mealType: MealType.fromJson(json['mealType'] as String),
        recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
        servings: json['servings'] as int,
      );
}
