import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Résultat d'une recherche Open Food Facts : seulement ce dont on a besoin
/// pour pré-remplir le formulaire de création de produit personnalisé.
class OpenFoodFactsProduct {
  const OpenFoodFactsProduct({
    required this.name,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
  });

  final String name;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
}

/// API publique d'Open Food Facts — aucune authentification, donc un Dio
/// séparé de celui de `dioProvider` (qui pointe vers NOTRE backend et y
/// injecte le JWT à chaque requête, ce qu'on ne veut surtout pas envoyer à
/// un service tiers).
final openFoodFactsClientProvider = Provider<OpenFoodFactsClient>((ref) {
  return OpenFoodFactsClient(Dio(BaseOptions(baseUrl: 'https://world.openfoodfacts.org/api/v2')));
});

class OpenFoodFactsClient {
  OpenFoodFactsClient(this._dio);

  final Dio _dio;

  /// Retourne `null` si le produit n'est pas référencé sur Open Food Facts
  /// (code `status == 0`) ou si la requête échoue (pas de réseau, timeout…)
  /// — dans les deux cas l'appelant retombe sur la saisie manuelle.
  Future<OpenFoodFactsProduct?> lookup(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/product/$barcode.json');
      final data = response.data!;
      if (data['status'] != 1) {
        return null;
      }

      final product = data['product'] as Map<String, dynamic>;
      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
      final name = (product['product_name'] as String?)?.trim();
      if (name == null || name.isEmpty) {
        return null;
      }

      return OpenFoodFactsProduct(
        name: name,
        caloriesPer100g: _num(nutriments['energy-kcal_100g']),
        proteinsPer100g: _num(nutriments['proteins_100g']),
        carbsPer100g: _num(nutriments['carbohydrates_100g']),
        fatsPer100g: _num(nutriments['fat_100g']),
      );
    } on DioException {
      return null;
    }
  }

  double _num(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }
}
