import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../../fridge/domain/storage_location.dart';
import '../domain/shopping_list.dart';

final shoppingListApiClientProvider = Provider<ShoppingListApiClient>((ref) {
  return ShoppingListApiClient(ref.watch(dioProvider));
});

/// Un élément à valider au checkout (voir `ShoppingListApiClient.checkout`).
class CheckoutItem {
  const CheckoutItem({required this.itemId, required this.storageLocation, required this.expirationDate});

  final int itemId;
  final StorageLocation storageLocation;
  final DateTime expirationDate;
}

class ShoppingListApiClient {
  ShoppingListApiClient(this._dio);

  final Dio _dio;
  static final _ldJson = Options(contentType: 'application/ld+json');

  /// `null` si le groupe n'a pas encore de liste active (aucune recette
  /// sélectionnée pour l'instant) — même principe que `fetchMyProfile`.
  Future<ShoppingList?> fetchActive(int groupId) async {
    final response = await _dio.get<Map<String, dynamic>>('/groups/$groupId/shopping_lists');
    final members = response.data!['member'] as List<dynamic>;

    return members.isEmpty ? null : ShoppingList.fromJson(members.first as Map<String, dynamic>);
  }

  /// `recipeIds` : ids de `Recipe`, convertis ici en IRIs — le backend
  /// calcule lui-même les quantités (nombre de membres du groupe).
  Future<ShoppingList> generate(int groupId, List<int> recipeIds) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/shopping_lists/generate',
      data: {'recipes': recipeIds.map((id) => '/api/recipes/$id').toList()},
      options: _ldJson,
    );

    return ShoppingList.fromJson(response.data!);
  }

  Future<ShoppingList> checkout(int groupId, List<CheckoutItem> items) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/shopping_lists/checkout',
      data: {
        'items': items
            .map((i) => {
                  'itemId': i.itemId,
                  'storageLocation': i.storageLocation.name,
                  'expirationDate': i.expirationDate.toIso8601String().split('T').first,
                })
            .toList(),
      },
      options: _ldJson,
    );

    return ShoppingList.fromJson(response.data!);
  }
}
