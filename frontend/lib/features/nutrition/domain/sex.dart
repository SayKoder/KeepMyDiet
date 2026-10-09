/// Miroir de `App\Domain\Nutrition\Entity\Sex` — paramètre physiologique
/// requis par la formule de Mifflin-St Jeor, pas un champ d'identité de
/// genre plus large.
enum Sex {
  male,
  female;

  factory Sex.fromJson(String value) => Sex.values.byName(value);

  String get label => switch (this) {
    Sex.male => 'Homme',
    Sex.female => 'Femme',
  };
}
