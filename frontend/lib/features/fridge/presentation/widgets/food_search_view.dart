import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/fridge/data/fridge_repository.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/presentation/barcode_scanner_screen.dart';
import 'package:keepmydiet/features/fridge/presentation/fridge_controller.dart';
import 'package:keepmydiet/features/fridge/presentation/widgets/food_form_dialog.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class FoodSearchView extends ConsumerStatefulWidget {
  const FoodSearchView({
    super.key,
    required this.groupId,
    required this.onSelected,
  });

  final int groupId;
  final ValueChanged<FoodReference> onSelected;

  @override
  ConsumerState<FoodSearchView> createState() => _FoodSearchViewState();
}

class _FoodSearchViewState extends ConsumerState<FoodSearchView> {
  final _searchController = TextEditingController();
  Timer? _onlineDebounce;
  List<OpenFoodFactsProduct> _onlineResults = const [];
  bool _onlineSearching = false;
  bool _onlineFailed = false;

  String get _query => _searchController.text.trim();

  @override
  void dispose() {
    _onlineDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Attend 450 ms sans frappe avant d'interroger Open Food Facts.
  void _onSearchChanged(String _) {
    _onlineDebounce?.cancel();
    final query = _query;

    setState(() {
      _onlineSearching = query.isNotEmpty;
      _onlineFailed = false;
      if (query.isEmpty) _onlineResults = const [];
    });
    if (query.isEmpty) return;

    _onlineDebounce = Timer(const Duration(milliseconds: 450), () async {
      var results = const <OpenFoodFactsProduct>[];
      var failed = false;
      try {
        results = await ref.read(fridgeRepositoryProvider).searchOnline(query);
      } catch (_) {
        failed = true;
      }
      if (!mounted || _query != query) return;
      setState(() {
        _onlineResults = results;
        _onlineFailed = failed;
        _onlineSearching = false;
      });
    });
  }

  Future<void> _createFood({
    String? name,
    OpenFoodFactsProduct? product,
    String? barcode,
  }) async {
    final food = await showCreateFoodDialog(
      context,
      groupId: widget.groupId,
      name: name ?? _query,
      product: product,
      barcode: barcode,
    );
    if (food != null) widget.onSelected(food);
  }

  Future<void> _editFood(FoodReference food) =>
      showEditFoodDialog(context, groupId: widget.groupId, food: food);

  // Produit déjà connu du groupe → sélection directe, sinon création
  // pré-remplie depuis Open Food Facts.
  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || !mounted) return;

    final catalog =
        ref.read(foodCatalogProvider(widget.groupId)).value ?? const [];
    final existing = catalog.where((f) => f.barcode == code).firstOrNull;
    if (existing != null) {
      widget.onSelected(existing);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingState(),
    );
    final product = await ref
        .read(fridgeRepositoryProvider)
        .lookupBarcode(code);
    if (!mounted) return;
    Navigator.of(context).pop();

    await _createFood(name: '', product: product, barcode: code);
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(foodCatalogProvider(widget.groupId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 12,
        children: [
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Rechercher un aliment',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scanner un code-barres',
                onPressed: _scanBarcode,
              ),
            ),
          ),
          Expanded(
            child: catalogAsync.toWidget(
              onRetry: () =>
                  ref.invalidate(foodCatalogProvider(widget.groupId)),
              data: _buildResults,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<FoodReference> catalog) {
    final query = _query.toLowerCase();
    final localMatches = catalog
        .where((food) => food.name.toLowerCase().contains(query))
        .toList();
    final knownBarcodes = {
      for (final food in catalog)
        if (food.barcode != null) food.barcode,
    };
    final onlineMatches = _onlineResults
        .where((product) => !knownBarcodes.contains(product.barcode))
        .toList();

    return ListView(
      children: [
        for (final food in localMatches)
          ListTile(
            title: Text(food.name),
            subtitle: Text(_kcalLabel(food.caloriesPer100g)),
            trailing: food.canEdit
                ? EditIconButton(onPressed: () => _editFood(food))
                : null,
            onTap: () => widget.onSelected(food),
          ),
        if (query.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'OPEN FOOD FACTS',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          if (_onlineSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LoadingState(),
            )
          else if (_onlineFailed)
            ListTile(
              title: const Text(
                'Recherche en ligne impossible.',
                style: TextStyle(color: AppColors.errorText),
              ),
              trailing: TextButton(
                onPressed: () => _onSearchChanged(_query),
                child: const Text('Réessayer'),
              ),
            )
          else if (onlineMatches.isEmpty)
            const ListTile(
              title: Text(
                'Aucun résultat en ligne pour cette recherche.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            for (final product in onlineMatches)
              ListTile(
                leading: const Icon(Icons.public),
                title: Text(product.name),
                subtitle: Text(_kcalLabel(product.caloriesPer100g)),
                onTap: () =>
                    _createFood(product: product, barcode: product.barcode),
              ),
        ],
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Créer un nouveau produit'),
          onTap: _createFood,
        ),
      ],
    );
  }

  String _kcalLabel(double kcal) => '${kcal.toStringAsFixed(0)} kcal / 100g';
}
