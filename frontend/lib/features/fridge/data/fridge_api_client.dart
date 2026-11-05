import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/fridge/domain/food_draft.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/domain/fridge_item.dart';
import 'package:keepmydiet/features/fridge/domain/storage_location.dart';
import 'package:keepmydiet/shared/api_client.dart';

final fridgeApiClientProvider = Provider<FridgeApiClient>((ref) {
  return FridgeApiClient(ref.watch(dioProvider));
});

class FridgeApiClient {
  FridgeApiClient(this._dio);

  final Dio _dio;
  static final _ldJson = Options(contentType: 'application/ld+json');

  Future<List<FoodReference>> fetchCatalog(int groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/food_references',
    );
    final members = response.data!['member'] as List<dynamic>;

    return members
        .map((e) => FoodReference.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FoodReference> createCustomFood(int groupId, FoodDraft draft) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/food_references',
      data: {...draft.toJson(), 'group': '/api/groups/$groupId'},
      options: _ldJson,
    );

    return FoodReference.fromJson(response.data!);
  }

  /// Réservé au créateur d'un aliment personnalisé (403 sinon).
  Future<FoodReference> updateCustomFood(int foodId, FoodDraft draft) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/food_references/$foodId',
      data: draft.toJson(),
      options: mergePatchOptions,
    );

    return FoodReference.fromJson(response.data!);
  }

  Future<List<FridgeItem>> fetchItems(int groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/fridge_items',
    );
    final members = response.data!['member'] as List<dynamic>;

    return members
        .map((e) => FridgeItem.fromJson(e as Map<String, dynamic>))
        .toList();
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
