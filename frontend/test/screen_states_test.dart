import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:keepmydiet/features/discover/presentation/discover_screen.dart';
import 'package:keepmydiet/features/discover/presentation/product_detail_screen.dart';
import 'package:keepmydiet/features/fridge/data/fridge_repository.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/presentation/fridge_controller.dart';
import 'package:keepmydiet/features/shopping_list/presentation/add_shopping_item_screen.dart';

import 'support/harness.dart';

const _retry = 'Réessayer';

Override _off(FakeOpenFoodFacts fake) =>
    openFoodFactsClientProvider.overrideWithValue(fake);

class _FakeFridgeRepository extends Fake implements FridgeRepository {
  _FakeFridgeRepository(this.onSearch);

  final Future<List<OpenFoodFactsProduct>> Function(String query) onSearch;

  @override
  Future<List<OpenFoodFactsProduct>> searchOnline(String query) =>
      onSearch(query);
}

void main() {
  group('Découvrir : les 4 états', () {
    testWidgets('chargement puis données', (tester) async {
      final response = Completer<OpenFoodFactsPage>();
      await pumpScreen(
        tester,
        const DiscoverScreen(),
        overrides: [
          _off(FakeOpenFoodFacts(onBrowse: (_, _) => response.future)),
        ],
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(_retry), findsNothing);

      response.complete(
        OpenFoodFactsPage(products: [product('Yaourt nature')], hasMore: false),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Yaourt nature'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await disposeScreen(tester);
    });

    testWidgets('vide : message sans bouton Réessayer', (tester) async {
      await pumpScreen(
        tester,
        const DiscoverScreen(),
        overrides: [
          _off(
            FakeOpenFoodFacts(
              onBrowse: (_, _) async =>
                  const OpenFoodFactsPage(products: [], hasMore: false),
            ),
          ),
        ],
      );

      expect(find.text('Aucun produit trouvé'), findsOneWidget);
      expect(find.text(_retry), findsNothing);
      await disposeScreen(tester);
    });

    testWidgets('erreur : Réessayer relance vraiment la requête', (
      tester,
    ) async {
      var calls = 0;
      await pumpScreen(
        tester,
        const DiscoverScreen(),
        overrides: [
          _off(
            FakeOpenFoodFacts(
              onBrowse: (_, _) async {
                if (++calls == 1) throw networkError();
                return OpenFoodFactsPage(
                  products: [product('Pain complet')],
                  hasMore: false,
                );
              },
            ),
          ),
        ],
      );

      expect(find.text(_retry), findsOneWidget);
      expect(find.text('Pain complet'), findsNothing);

      await tester.tap(find.text(_retry));
      await tester.pump();
      await tester.pump();

      expect(calls, 2);
      expect(find.text('Pain complet'), findsOneWidget);
      expect(find.text(_retry), findsNothing);
      await disposeScreen(tester);
    });
  });

  group('Détail produit : les 4 états', () {
    final listed = product('Yaourt nature', barcode: '123');

    testWidgets('chargement puis données', (tester) async {
      final response = Completer<OpenFoodFactsProduct?>();
      await pumpScreen(
        tester,
        ProductDetailScreen(product: listed),
        overrides: [_off(FakeOpenFoodFacts(onProduct: (_) => response.future))],
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      response.complete(
        const OpenFoodFactsProduct(
          name: 'Yaourt nature',
          caloriesPer100g: 60,
          proteinsPer100g: 4,
          carbsPer100g: 5,
          fatsPer100g: 3,
          barcode: '123',
          ingredients: 'Lait entier, ferments lactiques',
          allergens: ['milk'],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Lait entier, ferments lactiques'), findsOneWidget);
      expect(find.text('milk'), findsOneWidget);
      await disposeScreen(tester);
    });

    testWidgets('introuvable : message sans bouton Réessayer', (tester) async {
      await pumpScreen(
        tester,
        ProductDetailScreen(product: listed),
        overrides: [_off(FakeOpenFoodFacts(onProduct: (_) async => null))],
      );

      expect(
        find.text('Aucun détail disponible pour ce produit.'),
        findsOneWidget,
      );
      expect(find.text(_retry), findsNothing);
      await disposeScreen(tester);
    });

    testWidgets('erreur : Réessayer relance vraiment la requête', (
      tester,
    ) async {
      var calls = 0;
      await pumpScreen(
        tester,
        ProductDetailScreen(product: listed),
        overrides: [
          _off(
            FakeOpenFoodFacts(
              onProduct: (_) async {
                if (++calls == 1) throw networkError();
                return product('Yaourt nature', barcode: '123');
              },
            ),
          ),
        ],
      );

      expect(find.text('Chargement des détails impossible.'), findsOneWidget);

      await tester.tap(find.text(_retry));
      await tester.pump();
      await tester.pump();

      expect(calls, 2);
      expect(find.text('Chargement des détails impossible.'), findsNothing);
      await disposeScreen(tester);
    });
  });

  group('Recherche en ligne (ajout liste de courses / frigo)', () {
    Future<void> search(
      WidgetTester tester,
      Future<List<OpenFoodFactsProduct>> Function(String) onSearch,
    ) async {
      await pumpScreen(
        tester,
        const AddShoppingItemScreen(groupId: 1),
        overrides: [
          foodCatalogProvider.overrideWith(
            (ref, id) async => <FoodReference>[],
          ),
          fridgeRepositoryProvider.overrideWithValue(
            _FakeFridgeRepository(onSearch),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField), 'lait');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }

    testWidgets('aucun résultat : message sans bouton Réessayer', (
      tester,
    ) async {
      await search(tester, (_) async => const []);

      expect(
        find.text('Aucun résultat en ligne pour cette recherche.'),
        findsOneWidget,
      );
      expect(find.text(_retry), findsNothing);
      await disposeScreen(tester);
    });

    testWidgets('échec réseau : erreur avec Réessayer, pas "aucun résultat"', (
      tester,
    ) async {
      var calls = 0;
      await search(tester, (_) async {
        if (++calls == 1) throw networkError();
        return [product('Lait demi-écrémé')];
      });

      expect(find.text('Recherche en ligne impossible.'), findsOneWidget);
      expect(
        find.text('Aucun résultat en ligne pour cette recherche.'),
        findsNothing,
      );

      await tester.tap(find.text(_retry));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(calls, 2);
      expect(find.text('Lait demi-écrémé'), findsOneWidget);
      await disposeScreen(tester);
    });
  });
}
