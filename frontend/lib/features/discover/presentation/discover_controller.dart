import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';

class DiscoverState {
  const DiscoverState({
    required this.query,
    required this.products,
    required this.hasMore,
    this.page = 1,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final String query;
  final List<OpenFoodFactsProduct> products;
  final bool hasMore;
  final int page;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  DiscoverState copyWith({
    List<OpenFoodFactsProduct>? products,
    bool? hasMore,
    int? page,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) => DiscoverState(
    query: query,
    products: products ?? this.products,
    hasMore: hasMore ?? this.hasMore,
    page: page ?? this.page,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

final discoverProvider =
    AsyncNotifierProvider.autoDispose<DiscoverController, DiscoverState>(
      DiscoverController.new,
    );

class DiscoverController extends AsyncNotifier<DiscoverState> {
  int _request = 0;

  OpenFoodFactsClient get _client => ref.read(openFoodFactsClientProvider);

  @override
  Future<DiscoverState> build() => _firstPage('');

  Future<DiscoverState> _firstPage(String query) async {
    final page = await _client.browse(query);
    return DiscoverState(
      query: query,
      products: page.products,
      hasMore: page.hasMore,
    );
  }

  Future<void> search(String query) async {
    final request = ++_request;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _firstPage(query));
    if (ref.mounted && request == _request) state = result;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final request = _request;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final next = await _client.browse(current.query, page: current.page + 1);
      if (!ref.mounted || request != _request) return;
      state = AsyncData(
        current.copyWith(
          products: [...current.products, ...next.products],
          page: current.page + 1,
          hasMore: next.hasMore,
          isLoadingMore: false,
          loadMoreFailed: false,
        ),
      );
    } catch (_) {
      if (!ref.mounted || request != _request) return;
      state = AsyncData(current.copyWith(loadMoreFailed: true));
    }
  }
}

final productDetailProvider = FutureProvider.autoDispose
    .family<OpenFoodFactsProduct?, String>(
      (ref, barcode) => ref.watch(openFoodFactsClientProvider).lookup(barcode),
    );
