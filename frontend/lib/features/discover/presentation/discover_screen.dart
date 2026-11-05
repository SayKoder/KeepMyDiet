import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/discover/presentation/discover_controller.dart';
import 'package:keepmydiet/features/discover/presentation/product_detail_screen.dart';
import 'package:keepmydiet/features/discover/presentation/widgets/product_card.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';
import 'package:keepmydiet/features/fridge/presentation/barcode_scanner_screen.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  DiscoverController get _controller => ref.read(discoverProvider.notifier);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _loadMoreNearEnd(ScrollMetrics metrics) {
    final failed = ref.read(discoverProvider).value?.loadMoreFailed ?? false;
    if (!failed && metrics.extentAfter < 1000) _controller.loadMore();
    return false;
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 600),
      () => _controller.search(query.trim()),
    );
  }

  void _openDetail(OpenFoodFactsProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingState(),
    );
    final product = await ref.read(openFoodFactsClientProvider).lookup(code);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit introuvable sur Open Food Facts.'),
        ),
      );
      return;
    }
    _openDetail(product);
  }

  @override
  Widget build(BuildContext context) {
    final discoverAsync = ref.watch(discoverProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Découvrir des produits')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Rechercher un produit',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scanner un code-barres',
                  onPressed: _scanBarcode,
                ),
              ),
            ),
            Expanded(
              child: discoverAsync.toWidget(
                onRetry: () =>
                    _controller.search(_searchController.text.trim()),
                isEmpty: (state) => state.products.isEmpty,
                empty: const EmptyState(
                  icon: Icons.search_off,
                  title: 'Aucun produit trouvé',
                  message: 'Essaie un autre nom ou scanne un code-barres.',
                ),
                data: _buildGrid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(DiscoverState state) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _loadMoreNearEnd(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _loadMoreNearEnd(n.metrics),
        child: CustomScrollView(
          slivers: [
            SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisExtent: 250,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: state.products.length,
              itemBuilder: (_, index) => ProductCard(
                product: state.products[index],
                onTap: () => _openDetail(state.products[index]),
              ),
            ),
            SliverToBoxAdapter(child: _buildFooter(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(DiscoverState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LoadingState(),
      );
    }
    if (state.loadMoreFailed) {
      return Center(
        child: TextButton.icon(
          onPressed: _controller.loadMore,
          icon: const Icon(Icons.refresh),
          label: const Text('Erreur de chargement, réessayer'),
        ),
      );
    }
    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('Fin de la liste')),
      );
    }
    return const SizedBox(height: 16);
  }
}
