import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../../recipe_suggestions/presentation/recipe_suggestions_controller.dart';
import '../data/fridge_api_client.dart';
import '../domain/food_reference.dart';
import '../domain/fridge_failure.dart';
import '../domain/fridge_item.dart';
import '../domain/storage_location.dart';

/// `.family` par `groupId` : le frigo est propre à chaque groupe, pas à
/// l'utilisateur (contrairement aux recettes, pool global).
final foodCatalogProvider = FutureProvider.family<List<FoodReference>, int>((
  ref,
  groupId,
) {
  return ref.watch(fridgeApiClientProvider).fetchCatalog(groupId);
});

final fridgeItemsProvider = FutureProvider.family<List<FridgeItem>, int>((
  ref,
  groupId,
) {
  return ref.watch(fridgeApiClientProvider).fetchItems(groupId);
});

/// Pas de notifier dédié ici : juste des fonctions qui appellent l'API puis
/// invalident `fridgeItemsProvider` pour que la liste se recharge — plus
/// simple qu'un notifier "family" pour un écran qui n'a pas besoin de mise à
/// jour optimiste (l'attente d'un aller-retour réseau est acceptable ici).
Future<void> addFridgeItem(
  WidgetRef ref, {
  required int groupId,
  required int foodReferenceId,
  required StorageLocation storageLocation,
  required double quantity,
  required String unit,
  required DateTime expirationDate,
}) async {
  try {
    await ref
        .read(fridgeApiClientProvider)
        .addItem(
          groupId: groupId,
          foodReferenceId: foodReferenceId,
          storageLocation: storageLocation,
          quantity: quantity,
          unit: unit,
          expirationDate: expirationDate,
        );
  } on DioException catch (e) {
    throw FridgeFailure(extractErrorMessage(e));
  }

  ref.invalidate(fridgeItemsProvider(groupId));
  // Le contenu du frigo/placard change la couverture des suggestions de
  // recettes (ingrédients disponibles, DLC la plus proche) : sans ça, la
  // liste de suggestions reste figée sur l'état d'avant l'ajout.
  ref.invalidate(recipeSuggestionsProvider(groupId));
}

Future<void> deleteFridgeItem(
  WidgetRef ref, {
  required int groupId,
  required int itemId,
}) async {
  try {
    await ref.read(fridgeApiClientProvider).deleteItem(itemId);
  } on DioException catch (e) {
    throw FridgeFailure(extractErrorMessage(e));
  }

  ref.invalidate(fridgeItemsProvider(groupId));
  // Même raison que dans addFridgeItem : une suppression retire un
  // ingrédient potentiellement compté comme disponible dans une suggestion.
  ref.invalidate(recipeSuggestionsProvider(groupId));
}
