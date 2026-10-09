/// Miroir de `App\Domain\MealPlan\Entity\MealPlanEntryStatus`.
enum MealPlanEntryStatus {
  eaten,
  skipped,
  replaced;

  factory MealPlanEntryStatus.fromJson(String value) =>
      MealPlanEntryStatus.values.byName(value);

  String toJson() => name;
}
