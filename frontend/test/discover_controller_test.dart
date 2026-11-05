import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepmydiet/features/discover/presentation/discover_controller.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';

OpenFoodFactsProduct _product(String name) => OpenFoodFactsProduct(
  name: name,
  caloriesPer100g: 0,
  proteinsPer100g: 0,
  carbsPer100g: 0,
  fatsPer100g: 0,
);

OpenFoodFactsPage _page(List<String> names, {bool hasMore = true}) =>
    OpenFoodFactsPage(products: names.map(_product).toList(), hasMore: hasMore);

class _FakeClient extends OpenFoodFactsClient {
  _FakeClient(this.handler) : super(Dio());

  final Future<OpenFoodFactsPage> Function(String query, int page) handler;

  @override
  Future<OpenFoodFactsPage> browse(String query, {int page = 1}) =>
      handler(query, page);
}

ProviderContainer _container(
  Future<OpenFoodFactsPage> Function(String query, int page) handler,
) {
  final container = ProviderContainer(
    overrides: [
      openFoodFactsClientProvider.overrideWithValue(_FakeClient(handler)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(discoverProvider, (_, _) {});
  return container;
}

void main() {
  test(
    'loadMore ajoute la page suivante puis s\'arrête en fin de liste',
    () async {
      final container = _container(
        (query, page) async =>
            page == 1 ? _page(['a', 'b']) : _page(['c'], hasMore: false),
      );
      await container.read(discoverProvider.future);
      final controller = container.read(discoverProvider.notifier);

      await controller.loadMore();
      await controller.loadMore();

      final state = container.read(discoverProvider).value!;
      expect(state.products.map((p) => p.name), ['a', 'b', 'c']);
      expect(state.hasMore, isFalse);
    },
  );

  test('une erreur de page suivante ne bloque pas le chargement', () async {
    var fail = true;
    final container = _container((query, page) async {
      if (page == 1) return _page(['a']);
      if (fail) throw StateError('réponse invalide');
      return _page(['b'], hasMore: false);
    });
    await container.read(discoverProvider.future);
    final controller = container.read(discoverProvider.notifier);

    await controller.loadMore();
    var state = container.read(discoverProvider).value!;
    expect(state.loadMoreFailed, isTrue);
    expect(state.isLoadingMore, isFalse);

    fail = false;
    await controller.loadMore();
    state = container.read(discoverProvider).value!;
    expect(state.products.map((p) => p.name), ['a', 'b']);
    expect(state.loadMoreFailed, isFalse);
  });

  test(
    'une réponse tardive ne remplace pas une recherche plus récente',
    () async {
      final slow = Completer<OpenFoodFactsPage>();
      final container = _container((query, page) {
        if (query == 'lent') return slow.future;
        return Future.value(_page([query.isEmpty ? 'populaire' : query]));
      });
      await container.read(discoverProvider.future);
      final controller = container.read(discoverProvider.notifier);

      final first = controller.search('lent');
      await controller.search('rapide');
      slow.complete(_page(['lent']));
      await first;

      final state = container.read(discoverProvider).value!;
      expect(state.query, 'rapide');
      expect(state.products.single.name, 'rapide');
    },
  );
}
