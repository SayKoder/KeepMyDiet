/// Miroir de `App\Domain\Nutrition\Entity\ActivityLevel` — le multiplicateur
/// BMR→TDEE reste calculé côté backend, ici on n'a besoin que du libellé
/// affiché à l'utilisateur.
enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive;

  factory ActivityLevel.fromJson(String value) => switch (value) {
    'very_active' => ActivityLevel.veryActive,
    _ => ActivityLevel.values.byName(value),
  };

  String toJson() => switch (this) {
    ActivityLevel.veryActive => 'very_active',
    _ => name,
  };

  String get label => switch (this) {
    ActivityLevel.sedentary => 'Sédentaire (peu ou pas de sport)',
    ActivityLevel.light => 'Légère (1-3 fois/semaine)',
    ActivityLevel.moderate => 'Modérée (3-5 fois/semaine)',
    ActivityLevel.active => 'Active (6-7 fois/semaine)',
    ActivityLevel.veryActive => 'Très active (sport intense quotidien)',
  };
  String get shortLabel => switch (this) {
    ActivityLevel.sedentary => 'Sédentaire',
    ActivityLevel.light => 'Léger',
    ActivityLevel.moderate => 'Modéré',
    ActivityLevel.active => 'Actif',
    ActivityLevel.veryActive => 'Très actif',
  };
}
