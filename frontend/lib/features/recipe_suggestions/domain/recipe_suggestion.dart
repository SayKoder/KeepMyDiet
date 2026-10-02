/// Une recette du pool global, classée selon ce qui est déjà dans le
/// frigo/placard du groupe. Calculée à la volée côté backend, jamais
/// stockée — voir RecipeSuggestionsProvider.
class RecipeSuggestion {
  const RecipeSuggestion({
    required this.id,
    required this.name,
    required this.referenceServings,
    required this.caloriesPerServing,
    required this.matchedIngredientsCount,
    required this.totalIngredientsCount,
    required this.missingIngredientNames,
    required this.soonestExpirationDate,
  });

  final int id;
  final String name;
  final int referenceServings;
  final double caloriesPerServing;
  final int matchedIngredientsCount;
  final int totalIngredientsCount;
  final List<String> missingIngredientNames;

  /// DLC la plus proche parmi les ingrédients déjà en stock utilisés par
  /// cette recette — `null` si aucun ingrédient n'est disponible.
  final DateTime? soonestExpirationDate;

  bool get isFullyAvailable => totalIngredientsCount > 0 && matchedIngredientsCount == totalIngredientsCount;

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) => RecipeSuggestion(
        id: json['id'] as int,
        name: json['name'] as String,
        referenceServings: json['referenceServings'] as int,
        caloriesPerServing: (json['caloriesPerServing'] as num).toDouble(),
        matchedIngredientsCount: json['matchedIngredientsCount'] as int,
        totalIngredientsCount: json['totalIngredientsCount'] as int,
        missingIngredientNames:
            (json['missingIngredientNames'] as List<dynamic>).map((e) => e as String).toList(),
        soonestExpirationDate: json['soonestExpirationDate'] == null
            ? null
            : DateTime.parse(json['soonestExpirationDate'] as String),
      );
}
