import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/async_value_ui.dart';
import '../../../shared/dialog_action_buttons.dart';
import '../../../shared/form_error_text.dart';
import '../../../shared/ingredient_unit_field.dart';
import '../../../shared/submit_button_content.dart';
import '../data/fridge_api_client.dart';
import '../data/open_food_facts_client.dart';
import '../domain/food_reference.dart';
import '../domain/storage_location.dart';
import 'barcode_scanner_screen.dart';
import 'fridge_controller.dart';

/// Deux étapes dans un seul écran (pas de navigation supplémentaire) :
/// 1. Choisir un aliment du catalogue (recherche) ou en créer un nouveau.
/// 2. Une fois choisi, renseigner quantité/unité/lieu/DLC et valider.
class AddFridgeItemScreen extends ConsumerStatefulWidget {
  const AddFridgeItemScreen({
    super.key,
    required this.groupId,
    required this.defaultLocation,
  });

  final int groupId;
  final StorageLocation defaultLocation;

  @override
  ConsumerState<AddFridgeItemScreen> createState() =>
      _AddFridgeItemScreenState();
}

class _AddFridgeItemScreenState extends ConsumerState<AddFridgeItemScreen> {
  FoodReference? _selectedFood;
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  final _unitController = TextEditingController(text: 'g');
  late StorageLocation _storageLocation = widget.defaultLocation;
  DateTime? _expirationDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Recherche Open Food Facts déclenchée par la saisie, en plus du filtrage
  // local déjà fait sur `foodCatalogProvider` juste en dessous — même
  // service que celui utilisé par le scan, mais par nom plutôt que par
  // code-barres. `Timer`-based debounce (450ms) : sans lui, chaque frappe
  // partirait en requête réseau vers OFF.
  Timer? _offDebounce;
  List<OpenFoodFactsProduct> _offResults = const [];
  bool _offSearching = false;

  @override
  void dispose() {
    _offDebounce?.cancel();
    _searchController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // réapplique le filtre local tout de suite

    _offDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _offResults = const [];
        _offSearching = false;
      });
      return;
    }

    setState(() => _offSearching = true);
    _offDebounce = Timer(const Duration(milliseconds: 450), () async {
      final results = await ref.read(openFoodFactsClientProvider).search(query);
      // La requête la plus récente est la seule dont le résultat compte : si
      // le texte a encore changé entre-temps, une recherche plus récente est
      // déjà en vol (ou va l'être) — appliquer ce résultat-ci écraserait le
      // sien avec une réponse obsolète.
      if (mounted && _searchController.text.trim() == query) {
        setState(() {
          _offResults = results;
          _offSearching = false;
        });
      }
    });
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3 * 365)),
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  Future<void> _createCustomFood() async {
    final name = _searchController.text.trim();
    final result = await showDialog<FoodReference>(
      context: context,
      builder: (context) =>
          _CreateFoodDialog(groupId: widget.groupId, initialName: name),
    );
    if (result != null) {
      setState(() => _selectedFood = result);
    }
  }

  /// Ouvre la caméra, puis :
  /// 1. Si CE groupe a déjà un produit avec ce code-barres (recherche dans le
  ///    catalogue déjà chargé par `foodCatalogProvider`, pas d'appel réseau
  ///    en plus) → on le sélectionne directement, écran de détails.
  /// 2. Sinon → recherche sur Open Food Facts pour pré-remplir le formulaire
  ///    de création (nom + macros), qu'il trouve le produit ou non.
  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (code == null || !mounted) {
      return;
    }

    final catalog =
        ref.read(foodCatalogProvider(widget.groupId)).value ?? const [];
    final existing = catalog.where((f) => f.barcode == code).firstOrNull;
    if (existing != null) {
      setState(() => _selectedFood = existing);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final offProduct = await ref.read(openFoodFactsClientProvider).lookup(code);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();

    await _openCreateDialog(product: offProduct, barcode: code);
  }

  /// Ouvre la popup de création pré-remplie — partagée entre le scan
  /// (`_scanBarcode`, trouvé ou non sur Open Food Facts) et un résultat tapé
  /// dans la recherche texte (`_buildSearchStep`), pour ne pas dupliquer cet
  /// appel à chaque nouvelle source de résultat.
  Future<void> _openCreateDialog({
    OpenFoodFactsProduct? product,
    String? barcode,
  }) async {
    final result = await showDialog<FoodReference>(
      context: context,
      builder: (context) => _CreateFoodDialog(
        groupId: widget.groupId,
        initialName: product?.name ?? '',
        initialCalories: product?.caloriesPer100g,
        initialProteins: product?.proteinsPer100g,
        initialCarbs: product?.carbsPer100g,
        initialFats: product?.fatsPer100g,
        barcode: barcode,
      ),
    );
    if (result != null) {
      setState(() => _selectedFood = result);
    }
  }

  Future<void> _submit() async {
    final food = _selectedFood;
    final quantity = double.tryParse(_quantityController.text);
    final unit = _unitController.text.trim();

    if (food == null) {
      return;
    }
    if (quantity == null || quantity <= 0 || unit.isEmpty) {
      setState(() => _errorMessage = 'Quantité et unité invalides.');
      return;
    }
    if (_expirationDate == null) {
      setState(() => _errorMessage = 'Choisis une date de péremption.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await addFridgeItem(
        ref,
        groupId: widget.groupId,
        foodReferenceId: food.id,
        storageLocation: _storageLocation,
        quantity: quantity,
        unit: unit,
        expirationDate: _expirationDate!,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un aliment')),
      body: _selectedFood == null
          ? _buildSearchStep(context)
          : _buildDetailsStep(context),
    );
  }

  Widget _buildSearchStep(BuildContext context) {
    final catalogAsync = ref.watch(foodCatalogProvider(widget.groupId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Rechercher un aliment',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scanner un code-barres',
                onPressed: _scanBarcode,
              ),
            ),
            onChanged: (_) => _onSearchChanged(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: catalogAsync.toWidget(
              onRetry: () =>
                  ref.invalidate(foodCatalogProvider(widget.groupId)),
              data: (catalog) {
                final query = _searchController.text.trim().toLowerCase();
                final matches = query.isEmpty
                    ? catalog
                    : catalog
                          .where((f) => f.name.toLowerCase().contains(query))
                          .toList();
                // Un produit déjà dans le catalogue (Ciqual + perso du
                // groupe) n'a pas besoin d'être proposé une 2e fois depuis
                // Open Food Facts, même code-barres ou nom très proche.
                final knownBarcodes = catalog
                    .map((f) => f.barcode)
                    .whereType<String>()
                    .toSet();
                final offMatches = _offResults
                    .where((p) => !knownBarcodes.contains(p.barcode))
                    .toList();

                return ListView(
                  children: [
                    for (final food in matches)
                      ListTile(
                        title: Text(food.name),
                        subtitle: Text(
                          '${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
                        ),
                        onTap: () => setState(() => _selectedFood = food),
                      ),
                    if (query.isNotEmpty) ...[
                      const _SectionLabel('OPEN FOOD FACTS'),
                      if (_offSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else if (offMatches.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Aucun résultat en ligne pour cette recherche.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        for (final product in offMatches)
                          ListTile(
                            leading: const Icon(Icons.public),
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
                            ),
                            onTap: () => _openCreateDialog(
                              product: product,
                              barcode: product.barcode,
                            ),
                          ),
                    ],
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Créer un nouveau produit'),
                      onTap: _createCustomFood,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(BuildContext context) {
    final food = _selectedFood!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text(food.name),
            subtitle: Text(
              '${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
            ),
            trailing: TextButton(
              onPressed: () => setState(() => _selectedFood = null),
              child: const Text('Changer'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Quantité'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: IngredientUnitField(controller: _unitController)),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<StorageLocation>(
          segments: StorageLocation.values
              .map(
                (location) =>
                    ButtonSegment(value: location, label: Text(location.label)),
              )
              .toList(),
          selected: {_storageLocation},
          onSelectionChanged: (selection) =>
              setState(() => _storageLocation = selection.first),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Date de péremption'),
          subtitle: Text(
            _expirationDate == null
                ? 'Non renseignée'
                : '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: _pickExpirationDate,
        ),
        const SizedBox(height: 16),
        if (_errorMessage != null) FormErrorText(_errorMessage!),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: SubmitButtonContent(
            isSubmitting: _isSubmitting,
            label: const Text('Ajouter'),
          ),
        ),
      ],
    );
  }
}

class _CreateFoodDialog extends ConsumerStatefulWidget {
  const _CreateFoodDialog({
    required this.groupId,
    required this.initialName,
    this.initialCalories,
    this.initialProteins,
    this.initialCarbs,
    this.initialFats,
    this.barcode,
  });

  final int groupId;
  final String initialName;

  /// Préremplissage quand on arrive d'un scan ayant trouvé le produit sur
  /// Open Food Facts — `null` pour une création manuelle classique.
  final double? initialCalories;
  final double? initialProteins;
  final double? initialCarbs;
  final double? initialFats;

  /// Code scanné, à rattacher au produit créé pour le retrouver directement
  /// la prochaine fois (voir `_scanBarcode`). `null` en création manuelle.
  final String? barcode;

  @override
  ConsumerState<_CreateFoodDialog> createState() => _CreateFoodDialogState();
}

class _CreateFoodDialogState extends ConsumerState<_CreateFoodDialog> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _caloriesController = TextEditingController(
    text: _fmt(widget.initialCalories),
  );
  late final _proteinsController = TextEditingController(
    text: _fmt(widget.initialProteins),
  );
  late final _carbsController = TextEditingController(
    text: _fmt(widget.initialCarbs),
  );
  late final _fatsController = TextEditingController(
    text: _fmt(widget.initialFats),
  );
  bool _isSubmitting = false;
  String? _errorMessage;

  static String _fmt(double? value) => (value ?? 0).toString();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Le nom ne peut pas être vide.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final food = await ref
          .read(fridgeApiClientProvider)
          .createCustomFood(
            groupId: widget.groupId,
            name: name,
            caloriesPer100g: double.tryParse(_caloriesController.text) ?? 0,
            proteinsPer100g: double.tryParse(_proteinsController.text) ?? 0,
            carbsPer100g: double.tryParse(_carbsController.text) ?? 0,
            fatsPer100g: double.tryParse(_fatsController.text) ?? 0,
            barcode: widget.barcode,
          );
      ref.invalidate(foodCatalogProvider(widget.groupId));
      if (mounted) {
        Navigator.of(context).pop(food);
      }
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau produit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.barcode != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.initialName.isEmpty
                      ? "Code-barres ${widget.barcode} — introuvable sur Open Food Facts, à saisir manuellement"
                      : 'Pré-rempli depuis Open Food Facts (code ${widget.barcode}), vérifie avant de valider',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 16),
            const Text('Valeurs pour 100g :', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: _caloriesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Kcal'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _proteinsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Protéines'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _carbsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Glucides'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fatsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Lipides'),
            ),
            if (_errorMessage != null)
              FormErrorText(
                _errorMessage!,
                padding: const EdgeInsets.only(top: 12),
              ),
          ],
        ),
      ),
      actions: [
        DialogActionButtons(
          cancelLabel: 'Annuler',
          onCancel: _isSubmitting ? null : () => Navigator.of(context).pop(),
          confirmLabel: 'Créer',
          onConfirm: _isSubmitting ? null : _submit,
          confirmChild: SubmitButtonContent(
            isSubmitting: _isSubmitting,
            label: const Text('Créer'),
            size: 16,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.grey,
        ),
      ),
    );
  }
}
