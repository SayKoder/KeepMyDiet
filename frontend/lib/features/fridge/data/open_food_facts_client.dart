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
    this.barcode,
  });

  final String name;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double carbsPer100g;
  final double fatsPer100g;

  /// Renseigné pour un résultat de `search()` (on ne le connaît pas encore
  /// à ce stade) — `null` pour `lookup()`, où l'appelant connaît déjà le
  /// code-barres puisque c'est lui qui l'a fourni en entrée.
  final String? barcode;
}

/// API publique d'Open Food Facts — aucune authentification, donc un Dio
/// séparé de celui de `dioProvider` (qui pointe vers NOTRE backend et y
/// injecte le JWT à chaque requête, ce qu'on ne veut surtout pas envoyer à
/// un service tiers).
final openFoodFactsClientProvider = Provider<OpenFoodFactsClient>((ref) {
  return OpenFoodFactsClient(
    Dio(BaseOptions(baseUrl: 'https://world.openfoodfacts.org/api/v2')),
  );
});

class OpenFoodFactsClient {
  OpenFoodFactsClient(this._dio);

  final Dio _dio;

  /// Retourne `null` si le produit n'est pas référencé sur Open Food Facts
  /// (code `status == 0`) ou si la requête échoue (pas de réseau, timeout…)
  /// — dans les deux cas l'appelant retombe sur la saisie manuelle.
  Future<OpenFoodFactsProduct?> lookup(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/product/$barcode.json',
      );
      final data = response.data!;
      if (data['status'] != 1) {
        return null;
      }

      return _fromJson(data['product'] as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  /// Recherche par nom (barre de recherche du frigo/placard) — même service
  /// que `lookup()`, mais l'endpoint classique de recherche texte d'Open
  /// Food Facts (`/cgi/search.pl`) est à la racine du domaine, pas sous
  /// `/api/v2` comme `lookup()` : URL absolue plutôt que de changer le
  /// `baseUrl` partagé du client. Liste vide (pas d'exception) sur requête
  /// ratée ou vide — l'appelant retombe simplement sur le catalogue local.
  Future<List<OpenFoodFactsProduct>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://world.openfoodfacts.org/cgi/search.pl',
        queryParameters: {
          'search_terms': trimmed,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page_size': 20,
          'fields': 'code,product_name,nutriments',
        },
      );
      final products = response.data?['products'] as List<dynamic>? ?? [];

      return products
          .map((p) => _fromJson(p as Map<String, dynamic>))
          .whereType<OpenFoodFactsProduct>()
          .toList();
    } on DioException {
      return const [];
    }
  }

  OpenFoodFactsProduct? _fromJson(Map<String, dynamic> product) {
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
      barcode: product['code'] as String?,
    );
  }

  double _num(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }
}
