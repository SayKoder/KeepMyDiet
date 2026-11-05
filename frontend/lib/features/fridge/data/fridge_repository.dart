import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/fridge/data/fridge_api_client.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';
import 'package:keepmydiet/features/fridge/domain/food_draft.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/domain/fridge_item.dart';
import 'package:keepmydiet/features/fridge/domain/storage_location.dart';
import 'package:keepmydiet/shared/local_database.dart';
import 'package:keepmydiet/shared/network_first.dart';

final fridgeRepositoryProvider = Provider<FridgeRepository>((ref) {
  return FridgeRepository(
    ref.watch(fridgeApiClientProvider),
    ref.watch(openFoodFactsClientProvider),
    ref.watch(localDatabaseProvider),
  );
});

class FridgeRepository {
  FridgeRepository(this._api, this._openFoodFacts, this._database);

  final FridgeApiClient _api;
  final OpenFoodFactsClient _openFoodFacts;
  final LocalDatabase _database;

  Future<List<FoodReference>> fetchCatalog(int groupId) => networkFirst(
    _database,
    key: 'food_catalog_$groupId',
    fetch: () => _api.fetchCatalog(groupId),
    toJson: (foods) => [for (final food in foods) food.toJson()],
    fromJson: (json) => [
      for (final food in json as List)
        FoodReference.fromJson(food as Map<String, dynamic>),
    ],
  );

  Future<FoodReference> createCustomFood(int groupId, FoodDraft draft) =>
      _api.createCustomFood(groupId, draft);

  Future<FoodReference> updateCustomFood(int foodId, FoodDraft draft) =>
      _api.updateCustomFood(foodId, draft);

  Future<List<FridgeItem>> fetchItems(int groupId) => networkFirst(
    _database,
    key: 'fridge_items_$groupId',
    fetch: () => _api.fetchItems(groupId),
    toJson: (items) => [for (final item in items) item.toJson()],
    fromJson: (json) => [
      for (final item in json as List)
        FridgeItem.fromJson(item as Map<String, dynamic>),
    ],
  );

  Future<void> addItem({
    required int groupId,
    required int foodReferenceId,
    required StorageLocation storageLocation,
    required double quantity,
    required String unit,
    required DateTime expirationDate,
  }) => _api.addItem(
    groupId: groupId,
    foodReferenceId: foodReferenceId,
    storageLocation: storageLocation,
    quantity: quantity,
    unit: unit,
    expirationDate: expirationDate,
  );

  Future<void> deleteItem(int id) => _api.deleteItem(id);

  Future<OpenFoodFactsProduct?> lookupBarcode(String barcode) =>
      _openFoodFacts.lookup(barcode);

  Future<List<OpenFoodFactsProduct>> searchOnline(String query) async =>
      (await _openFoodFacts.browse(query)).products;
}
