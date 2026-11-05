import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/shopping_list/data/shopping_list_api_client.dart';
import 'package:keepmydiet/features/shopping_list/domain/shopping_list.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepository(ref.watch(shoppingListApiClientProvider));
});

class ShoppingListRepository {
  ShoppingListRepository(this._api);

  final ShoppingListApiClient _api;

  Future<ShoppingList?> fetchActive(int groupId) => _api.fetchActive(groupId);

  Future<ShoppingList> generate(int groupId, List<int> recipeIds) =>
      _api.generate(groupId, recipeIds);

  Future<ShoppingList> checkout(int groupId, List<CheckoutItem> items) =>
      _api.checkout(groupId, items);
}
