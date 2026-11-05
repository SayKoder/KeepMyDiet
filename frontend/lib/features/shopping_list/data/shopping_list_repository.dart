import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/shopping_list/data/shopping_list_api_client.dart';
import 'package:keepmydiet/features/shopping_list/domain/shopping_list.dart';
import 'package:keepmydiet/shared/local_database.dart';
import 'package:keepmydiet/shared/network_first.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepository(
    ref.watch(shoppingListApiClientProvider),
    ref.watch(localDatabaseProvider),
  );
});

class ShoppingListRepository {
  ShoppingListRepository(this._api, this._database);

  final ShoppingListApiClient _api;
  final LocalDatabase _database;

  Future<ShoppingList?> fetchActive(int groupId) => networkFirst(
    _database,
    key: 'shopping_list_$groupId',
    fetch: () => _api.fetchActive(groupId),
    toJson: (list) => list?.toJson(),
    fromJson: (json) => json == null
        ? null
        : ShoppingList.fromJson(json as Map<String, dynamic>),
  );

  Future<ShoppingList> generate(int groupId, List<int> recipeIds) =>
      _api.generate(groupId, recipeIds);

  Future<ShoppingList> checkout(int groupId, List<CheckoutItem> items) =>
      _api.checkout(groupId, items);
}
