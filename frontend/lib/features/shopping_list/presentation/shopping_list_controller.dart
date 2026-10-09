import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../../fridge/presentation/fridge_controller.dart';
import '../../recipe_suggestions/presentation/recipe_suggestions_controller.dart';
import '../data/shopping_list_api_client.dart';
import '../domain/shopping_list.dart';
import '../domain/shopping_list_failure.dart';

/// `.family` par `groupId`, comme le frigo : la liste de courses est propre
/// à chaque groupe.
final shoppingListProvider = FutureProvider.family<ShoppingList?, int>((
  ref,
  groupId,
) {
  return ref.watch(shoppingListApiClientProvider).fetchActive(groupId);
});

Future<void> generateShoppingList(
  WidgetRef ref, {
  required int groupId,
  required List<int> recipeIds,
}) async {
  try {
    await ref.read(shoppingListApiClientProvider).generate(groupId, recipeIds);
  } on DioException catch (e) {
    throw ShoppingListFailure(extractErrorMessage(e));
  }

  ref.invalidate(shoppingListProvider(groupId));
}

Future<void> checkoutShoppingList(
  WidgetRef ref, {
  required int groupId,
  required List<CheckoutItem> items,
}) async {
  try {
    await ref.read(shoppingListApiClientProvider).checkout(groupId, items);
  } on DioException catch (e) {
    throw ShoppingListFailure(extractErrorMessage(e));
  }

  ref.invalidate(shoppingListProvider(groupId));
  // Le checkout crée des FridgeItem côté backend : il faut invalider le
  // cache du frigo sinon l'écran Frigo garde l'ancienne liste en mémoire
  // (FutureProvider non-autoDispose) et les articles achetés n'apparaissent
  // pas tant qu'on ne fait pas un pull-to-refresh manuel.
  ref.invalidate(fridgeItemsProvider(groupId));
  // Pour la même raison, les suggestions de recettes doivent être
  // recalculées puisque le stock disponible vient de changer.
  ref.invalidate(recipeSuggestionsProvider(groupId));
}
