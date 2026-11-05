/// Ce que le formulaire d'un aliment personnalisé envoie, à la création comme
/// à la modification (valeurs nutritionnelles pour 100g).
class FoodDraft {
  const FoodDraft({
    required this.name,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    this.barcode,
  });

  final String name;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final String? barcode;

  Map<String, dynamic> toJson() => {
    'name': name,
    'caloriesPer100g': caloriesPer100g,
    'proteinsPer100g': proteinsPer100g,
    'carbsPer100g': carbsPer100g,
    'fatsPer100g': fatsPer100g,
    'barcode': ?barcode,
  };
}
