/// Un aliment du catalogue (seed Ciqual global, ou produit personnalisé
/// propre à un groupe) — valeurs nutritionnelles toujours pour 100g.
class FoodReference {
  const FoodReference({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    this.barcode,
  });

  final int id;
  final String name;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final String? barcode;

  factory FoodReference.fromJson(Map<String, dynamic> json) => FoodReference(
    id: json['id'] as int,
    name: json['name'] as String,
    caloriesPer100g: (json['caloriesPer100g'] as num).toDouble(),
    proteinsPer100g: (json['proteinsPer100g'] as num).toDouble(),
    carbsPer100g: (json['carbsPer100g'] as num).toDouble(),
    fatsPer100g: (json['fatsPer100g'] as num).toDouble(),
    barcode: json['barcode'] as String?,
  );
}
