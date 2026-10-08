class MealPlanFailure implements Exception {
  const MealPlanFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
