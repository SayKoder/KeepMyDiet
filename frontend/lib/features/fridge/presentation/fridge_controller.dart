import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/fridge/data/fridge_repository.dart';
import 'package:keepmydiet/features/fridge/domain/food_draft.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/domain/fridge_failure.dart';
import 'package:keepmydiet/features/fridge/domain/fridge_item.dart';
import 'package:keepmydiet/features/fridge/domain/storage_location.dart';
import 'package:keepmydiet/features/recipe_suggestions/presentation/recipe_suggestions_controller.dart';
import 'package:keepmydiet/shared/api_client.dart';

/// `.family` par `groupId` : le frigo est propre à chaque groupe, pas à
/// l'utilisateur (contrairement aux recettes, pool global).
final foodCatalogProvider = FutureProvider.family<List<FoodReference>, int>((
  ref,
  groupId,
) {
  return ref.watch(fridgeRepositoryProvider).fetchCatalog(groupId);
});

final fridgeItemsProvider = FutureProvider.family<List<FridgeItem>, int>((
  ref,
  groupId,
) {
  return ref.watch(fridgeRepositoryProvider).fetchItems(groupId);
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
        .read(fridgeRepositoryProvider)
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

Future<FoodReference> createCustomFood(
  WidgetRef ref, {
  required int groupId,
  required FoodDraft draft,
}) async {
  final FoodReference food;
  try {
    food = await ref
        .read(fridgeRepositoryProvider)
        .createCustomFood(groupId, draft);
  } on DioException catch (e) {
    throw FridgeFailure(extractErrorMessage(e));
  }

  ref.invalidate(foodCatalogProvider(groupId));

  return food;
}

Future<FoodReference> updateCustomFood(
  WidgetRef ref, {
  required int groupId,
  required int foodId,
  required FoodDraft draft,
}) async {
  final FoodReference food;
  try {
    food = await ref
        .read(fridgeRepositoryProvider)
        .updateCustomFood(foodId, draft);
  } on DioException catch (e) {
    throw FridgeFailure(extractErrorMessage(e));
  }

  ref.invalidate(foodCatalogProvider(groupId));
  // Les articles du frigo et les suggestions de recettes affichent le nom et
  // les macros de l'aliment : ils doivent se recharger eux aussi.
  ref.invalidate(fridgeItemsProvider(groupId));
  ref.invalidate(recipeSuggestionsProvider(groupId));

  return food;
}

Future<void> deleteFridgeItem(
  WidgetRef ref, {
  required int groupId,
  required int itemId,
}) async {
  try {
    await ref.read(fridgeRepositoryProvider).deleteItem(itemId);
  } on DioException catch (e) {
    throw FridgeFailure(extractErrorMessage(e));
  }

  ref.invalidate(fridgeItemsProvider(groupId));
  // Même raison que dans addFridgeItem : une suppression retire un
  // ingrédient potentiellement compté comme disponible dans une suggestion.
  ref.invalidate(recipeSuggestionsProvider(groupId));
}
