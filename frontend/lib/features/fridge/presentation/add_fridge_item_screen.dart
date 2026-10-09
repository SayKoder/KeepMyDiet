import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/async_value_ui.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
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

    final result = await showDialog<FoodReference>(
      context: context,
      builder: (context) => _CreateFoodDialog(
        groupId: widget.groupId,
        initialName: offProduct?.name ?? '',
        initialCalories: offProduct?.caloriesPer100g,
        initialProteins: offProduct?.proteinsPer100g,
        initialCarbs: offProduct?.carbsPer100g,
        initialFats: offProduct?.fatsPer100g,
        barcode: code,
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
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: catalogAsync.toWidget(
              data: (catalog) {
                final query = _searchController.text.trim().toLowerCase();
                final matches = query.isEmpty
                    ? catalog
                    : catalog
                          .where((f) => f.name.toLowerCase().contains(query))
                          .toList();

                return ListView.builder(
                  itemCount: matches.length + 1,
                  itemBuilder: (context, index) {
                    if (index == matches.length) {
                      return ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Créer un nouveau produit'),
                        onTap: _createCustomFood,
                      );
                    }
                    final food = matches[index];

                    return ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
                      ),
                      onTap: () => setState(() => _selectedFood = food),
                    );
                  },
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
            const SizedBox(height: 8),
            const Text('Valeurs pour 100g :', style: TextStyle(fontSize: 12)),
            TextField(
              controller: _caloriesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Kcal'),
            ),
            TextField(
              controller: _proteinsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Protéines'),
            ),
            TextField(
              controller: _carbsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Glucides'),
            ),
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
                padding: const EdgeInsets.only(top: 8),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: SubmitButtonContent(
            isSubmitting: _isSubmitting,
            label: const Text('Créer'),
            size: 16,
          ),
        ),
      ],
    );
  }
}
