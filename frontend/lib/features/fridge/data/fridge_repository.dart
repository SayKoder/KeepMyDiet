import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/fridge/data/fridge_api_client.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/domain/fridge_item.dart';
import 'package:keepmydiet/features/fridge/domain/storage_location.dart';

final fridgeRepositoryProvider = Provider<FridgeRepository>((ref) {
  return FridgeRepository(
    ref.watch(fridgeApiClientProvider),
    ref.watch(openFoodFactsClientProvider),
  );
});

class FridgeRepository {
  FridgeRepository(this._api, this._openFoodFacts);

  final FridgeApiClient _api;
  final OpenFoodFactsClient _openFoodFacts;

  Future<List<FoodReference>> fetchCatalog(int groupId) =>
      _api.fetchCatalog(groupId);

  Future<FoodReference> createCustomFood({
    required int groupId,
    required String name,
    required double caloriesPer100g,
    required double proteinsPer100g,
    required double carbsPer100g,
    required double fatsPer100g,
    String? barcode,
  }) => _api.createCustomFood(
    groupId: groupId,
    name: name,
    caloriesPer100g: caloriesPer100g,
    proteinsPer100g: proteinsPer100g,
    carbsPer100g: carbsPer100g,
    fatsPer100g: fatsPer100g,
    barcode: barcode,
  );

  Future<List<FridgeItem>> fetchItems(int groupId) => _api.fetchItems(groupId);

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

  Future<List<OpenFoodFactsProduct>> searchOnline(String query) =>
      _openFoodFacts.search(query);
}
