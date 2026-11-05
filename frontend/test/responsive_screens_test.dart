import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:keepmydiet/features/discover/presentation/discover_screen.dart';
import 'package:keepmydiet/features/discover/presentation/product_detail_screen.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/presentation/fridge_controller.dart';
import 'package:keepmydiet/features/groups/presentation/create_group_screen.dart';
import 'package:keepmydiet/features/groups/presentation/group_events_controller.dart';
import 'package:keepmydiet/features/shopping_list/domain/shopping_list.dart';
import 'package:keepmydiet/features/shopping_list/domain/shopping_list_item.dart';
import 'package:keepmydiet/features/shopping_list/presentation/add_shopping_item_screen.dart';
import 'package:keepmydiet/features/shopping_list/presentation/shopping_list_controller.dart';
import 'package:keepmydiet/features/shopping_list/presentation/shopping_list_screen.dart';

import 'support/harness.dart';

const _longName =
    'Yaourt brassé nature au lait entier de montagne bio équitable 4 x 125 g';

const _sizes = {
  'portrait': phonePortrait,
  'paysage': phoneLandscape,
  'tablette portrait': tabletPortrait,
  'tablette paysage': tabletLandscape,
};

final _fullProduct = OpenFoodFactsProduct(
  name: _longName,
  caloriesPer100g: 61,
  proteinsPer100g: 4.2,
  carbsPer100g: 5.1,
  fatsPer100g: 3.3,
  barcode: '123',
  nutriScore: 'B',
  ingredients: List.filled(40, 'lait entier pasteurisé').join(', '),
  allergens: const ['milk', 'gluten', 'eggs', 'soybeans', 'peanuts', 'celery'],
);

final _discoverOverride = openFoodFactsClientProvider.overrideWithValue(
  FakeOpenFoodFacts(
    onBrowse: (_, _) async => OpenFoodFactsPage(
      products: [for (var i = 0; i < 24; i++) product('$_longName $i')],
      hasMore: true,
    ),
    onProduct: (_) async => _fullProduct,
  ),
);

final List<Override> _shoppingOverrides = [
  shoppingListProvider.overrideWith(
    (ref, id) async => ShoppingList(
      id: 1,
      items: [
        for (var i = 0; i < 12; i++)
          ShoppingListItem.fromJson({
            'id': i,
            'name': '$_longName $i',
            'quantity': 2.5,
            'unit': 'pièce',
            'caloriesPer100g': 60,
            'proteinsPer100g': 4,
            'carbsPer100g': 5,
            'fatsPer100g': 3,
            'sourceRecipeName': i.isEven
                ? 'Gratin dauphinois du dimanche'
                : null,
          }),
      ],
    ),
  ),
  groupEventsProvider.overrideWith((ref, id) => const Stream.empty()),
];

final _catalogOverride = foodCatalogProvider.overrideWith(
  (ref, id) async => [
    const FoodReference(
      id: 1,
      name: _longName,
      caloriesPer100g: 61,
      proteinsPer100g: 4,
      carbsPer100g: 5,
      fatsPer100g: 3,
    ),
  ],
);

void main() {
  for (final MapEntry(key: label, value: size) in _sizes.entries) {
    for (final scale in [1.0, 1.5]) {
      group('$label, texte x$scale', () {
        Future<void> expectNoOverflow(
          WidgetTester tester,
          Widget screen, {
          List<Override> overrides = const [],
          double keyboardHeight = 0,
          Future<void> Function()? then,
        }) async {
          final errors = <FlutterErrorDetails>[];
          final previous = FlutterError.onError;
          FlutterError.onError = errors.add;

          await pumpScreen(
            tester,
            screen,
            size: size,
            textScale: scale,
            keyboardHeight: keyboardHeight,
            overrides: overrides,
          );
          await then?.call();
          await disposeScreen(tester);
          FlutterError.onError = previous;

          expect(
            errors,
            isEmpty,
            reason: errors.map((e) => e.toString()).join('\n'),
          );
        }

        testWidgets('Découvrir', (tester) async {
          await expectNoOverflow(
            tester,
            const DiscoverScreen(),
            overrides: [_discoverOverride],
          );
        });

        testWidgets('Détail produit', (tester) async {
          await expectNoOverflow(
            tester,
            ProductDetailScreen(product: product(_longName, barcode: '123')),
            overrides: [_discoverOverride],
          );
        });

        testWidgets('Liste de courses', (tester) async {
          await expectNoOverflow(
            tester,
            const ShoppingListScreen(groupId: 1, groupName: 'Famille'),
            overrides: _shoppingOverrides,
          );
        });

        testWidgets('Ajout à la liste : recherche puis quantité', (
          tester,
        ) async {
          await expectNoOverflow(
            tester,
            const AddShoppingItemScreen(groupId: 1),
            overrides: [_catalogOverride],
            then: () async {
              expect(tester.takeException(), isNull);
              await tester.tap(find.text(_longName));
              await tester.pump();
            },
          );
        });

        testWidgets('Formulaire à un champ, clavier ouvert', (tester) async {
          await expectNoOverflow(
            tester,
            const CreateGroupScreen(),
            keyboardHeight: 216,
          );
        });
      });
    }
  }
}
