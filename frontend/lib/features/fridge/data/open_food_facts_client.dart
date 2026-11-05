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
    this.imageUrl,
    this.nutriScore,
    this.ingredients,
    this.allergens = const [],
  });

  final String name;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final String? barcode;
  final String? imageUrl;
  final String? nutriScore;
  final String? ingredients;
  final List<String> allergens;
}

class OpenFoodFactsPage {
  const OpenFoodFactsPage({required this.products, required this.hasMore});

  final List<OpenFoodFactsProduct> products;
  final bool hasMore;
}

/// API publique d'Open Food Facts — aucune authentification, donc un Dio
/// séparé de celui de `dioProvider` (qui pointe vers NOTRE backend et y
/// injecte le JWT à chaque requête, ce qu'on ne veut surtout pas envoyer à
/// un service tiers).
final openFoodFactsClientProvider = Provider<OpenFoodFactsClient>((ref) {
  return OpenFoodFactsClient(
    Dio(
      BaseOptions(
        baseUrl: 'https://world.openfoodfacts.org/api/v2',
        headers: {'User-Agent': 'KeepMyDiet - Flutter - projet étudiant'},
      ),
    ),
  );
});

class OpenFoodFactsClient {
  OpenFoodFactsClient(this._dio);

  static const _pageSize = 24;

  final Dio _dio;

  /// Retourne `null` si le produit n'est pas référencé sur Open Food Facts
  /// (code `status == 0`) ou si la requête échoue (pas de réseau, timeout…)
  /// — dans les deux cas l'appelant retombe sur la saisie manuelle.
  Future<OpenFoodFactsProduct?> lookup(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/product/$barcode.json',
        queryParameters: {'fields': _detailFields},
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
    if (query.trim().isEmpty) {
      return const [];
    }

    try {
      return (await browse(query)).products;
    } on DioException {
      return const [];
    }
  }

  /// Version paginée de `search()` pour l'écran Découvrir : lève
  /// `DioException` pour que l'écran affiche l'erreur. Une requête vide passe
  /// par `/search` (v2, tri par popularité, bien plus rapide que le tri de
  /// `search.pl`). `hasMore` vient du total annoncé par l'API, pas de la page
  /// reçue : une page vide ou filtrée ne doit pas arrêter le défilement.
  Future<OpenFoodFactsPage> browse(String query, {int page = 1}) async {
    final trimmed = query.trim();
    final params = {
      'page': page,
      'page_size': _pageSize,
      'fields': 'code,product_name,nutriments,image_front_small_url',
    };
    final response = trimmed.isEmpty
        ? await _dio.get<Map<String, dynamic>>(
            '/search',
            queryParameters: {...params, 'sort_by': 'popularity_key'},
          )
        : await _dio.get<Map<String, dynamic>>(
            'https://world.openfoodfacts.org/cgi/search.pl',
            queryParameters: {
              ...params,
              'search_terms': trimmed,
              'search_simple': 1,
              'action': 'process',
              'json': 1,
            },
          );
    final data = response.data ?? const {};
    final total = int.tryParse('${data['count']}') ?? 0;
    final products = data['products'] as List<dynamic>? ?? [];

    return OpenFoodFactsPage(
      products: products
          .map((p) => _fromJson(p as Map<String, dynamic>))
          .whereType<OpenFoodFactsProduct>()
          .toList(),
      hasMore: page * _pageSize < total,
    );
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
      imageUrl:
          (product['image_front_url'] ?? product['image_front_small_url'])
              as String?,
      nutriScore: _nutriScore(product),
      ingredients: (product['ingredients_text'] as String?)?.trim(),
      allergens: [
        for (final tag in product['allergens_tags'] as List<dynamic>? ?? [])
          (tag as String).replaceFirst(RegExp(r'^\w+:'), ''),
      ],
    );
  }

  String? _nutriScore(Map<String, dynamic> product) {
    final grade = product['nutriscore_grade'] ?? product['nutrition_grades'];
    return grade is String && grade.length == 1 ? grade.toUpperCase() : null;
  }

  static const _detailFields =
      'code,product_name,nutriments,image_front_url,ingredients_text,'
      'allergens_tags,nutriscore_grade,nutrition_grades';

  double _num(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }
}
