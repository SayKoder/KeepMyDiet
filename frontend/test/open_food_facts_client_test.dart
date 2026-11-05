import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

OpenFoodFactsClient _client(Map<String, dynamic> body) =>
    OpenFoodFactsClient(Dio()..httpClientAdapter = _FakeAdapter(body));

void main() {
  test('lookup lit Nutri-Score, ingrédients, allergènes et photo', () async {
    final product = await _client({
      'status': 1,
      'product': {
        'code': '123',
        'product_name': 'Yaourt',
        'nutriments': {'energy-kcal_100g': 60},
        'nutriscore_grade': 'b',
        'ingredients_text': 'Lait, ferments',
        'allergens_tags': ['en:milk', 'fr:oeufs'],
        'image_front_url': 'https://img/large.jpg',
      },
    }).lookup('123');

    expect(product?.barcode, '123');
    expect(product?.caloriesPer100g, 60);
    expect(product?.nutriScore, 'B');
    expect(product?.ingredients, 'Lait, ferments');
    expect(product?.allergens, ['milk', 'oeufs']);
    expect(product?.imageUrl, 'https://img/large.jpg');
  });

  test('browse ignore les produits sans nom', () async {
    final products = await _client({
      'products': [
        {'code': '1', 'product_name': 'Pain'},
        {'code': '2', 'product_name': '  '},
      ],
    }).browse('');

    expect(products.map((p) => p.name), ['Pain']);
    expect(products.single.nutriScore, isNull);
  });
}
