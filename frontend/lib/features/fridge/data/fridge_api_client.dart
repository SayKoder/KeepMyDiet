import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../domain/food_reference.dart';
import '../domain/fridge_item.dart';
import '../domain/storage_location.dart';

final fridgeApiClientProvider = Provider<FridgeApiClient>((ref) {
  return FridgeApiClient(ref.watch(dioProvider));
});

class FridgeApiClient {
  FridgeApiClient(this._dio);

  final Dio _dio;
  static final _ldJson = Options(contentType: 'application/ld+json');

  Future<List<FoodReference>> fetchCatalog(int groupId) async {
    final response = await _dio.get<Map<String, dynamic>>('/groups/$groupId/food_references');
    final members = response.data!['member'] as List<dynamic>;

    return members.map((e) => FoodReference.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FoodReference> createCustomFood({
    required int groupId,
    required String name,
    required double caloriesPer100g,
    required double proteinsPer100g,
    required double carbsPer100g,
    required double fatsPer100g,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/food_references',
      data: {
        'name': name,
        'caloriesPer100g': caloriesPer100g,
        'proteinsPer100g': proteinsPer100g,
        'carbsPer100g': carbsPer100g,
        'fatsPer100g': fatsPer100g,
        'group': '/api/groups/$groupId',
      },
      options: _ldJson,
    );

    return FoodReference.fromJson(response.data!);
  }

  Future<List<FridgeItem>> fetchItems(int groupId) async {
    final response = await _dio.get<Map<String, dynamic>>('/groups/$groupId/fridge_items');
    final members = response.data!['member'] as List<dynamic>;

    return members.map((e) => FridgeItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Ne retourne rien : la réponse de ce POST n'embarque que l'IRI de
  /// `foodReference`, pas ses macros (particularité backend non élucidée,
  /// voir CreateFridgeItemProcessor) — de toute façon, l'appelant
  /// (`addFridgeItem`) rafraîchit toujours la liste via `fetchItems` juste
  /// après, donc ce retour ne serait jamais utilisé.
  Future<void> addItem({
    required int groupId,
    required int foodReferenceId,
    required StorageLocation storageLocation,
    required double quantity,
    required String unit,
    required DateTime expirationDate,
  }) async {
    await _dio.post<void>(
      '/fridge_items',
      data: {
        'group': '/api/groups/$groupId',
        'foodReference': '/api/food_references/$foodReferenceId',
        'storageLocation': storageLocation.name,
        'quantity': quantity,
        'unit': unit,
        'expirationDate': expirationDate.toIso8601String().split('T').first,
      },
      options: _ldJson,
    );
  }

  Future<void> deleteItem(int id) async {
    await _dio.delete<void>('/fridge_items/$id');
  }
}
