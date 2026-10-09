/// Miroir de `App\Domain\MealPlan\Entity\MealType`.
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  factory MealType.fromJson(String value) => MealType.values.byName(value);

  String toJson() => name;

  String get label => switch (this) {
    MealType.breakfast => 'Petit-déjeuner',
    MealType.lunch => 'Déjeuner',
    MealType.dinner => 'Dîner',
    MealType.snack => 'Collation',
  };
}
