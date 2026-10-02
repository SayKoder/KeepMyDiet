import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fridge_api_client.dart';
import '../domain/food_reference.dart';
import '../domain/storage_location.dart';
import 'fridge_controller.dart';

/// Deux étapes dans un seul écran (pas de navigation supplémentaire) :
/// 1. Choisir un aliment du catalogue (recherche) ou en créer un nouveau.
/// 2. Une fois choisi, renseigner quantité/unité/lieu/DLC et valider.
class AddFridgeItemScreen extends ConsumerStatefulWidget {
  const AddFridgeItemScreen({super.key, required this.groupId, required this.defaultLocation});

  final int groupId;
  final StorageLocation defaultLocation;

  @override
  ConsumerState<AddFridgeItemScreen> createState() => _AddFridgeItemScreenState();
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
      builder: (context) => _CreateFoodDialog(groupId: widget.groupId, initialName: name),
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
      body: _selectedFood == null ? _buildSearchStep(context) : _buildDetailsStep(context),
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
            decoration: const InputDecoration(labelText: 'Rechercher un aliment', prefixIcon: Icon(Icons.search)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: catalogAsync.when(
              data: (catalog) {
                final query = _searchController.text.trim().toLowerCase();
                final matches = query.isEmpty
                    ? catalog
                    : catalog.where((f) => f.name.toLowerCase().contains(query)).toList();

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
                      subtitle: Text('${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g'),
                      onTap: () => setState(() => _selectedFood = food),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erreur : $error')),
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
            subtitle: Text('${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g'),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantité'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unité'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<StorageLocation>(
          segments: StorageLocation.values
              .map((location) => ButtonSegment(value: location, label: Text(location.label)))
              .toList(),
          selected: {_storageLocation},
          onSelectionChanged: (selection) => setState(() => _storageLocation = selection.first),
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
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _CreateFoodDialog extends ConsumerStatefulWidget {
  const _CreateFoodDialog({required this.groupId, required this.initialName});

  final int groupId;
  final String initialName;

  @override
  ConsumerState<_CreateFoodDialog> createState() => _CreateFoodDialogState();
}

class _CreateFoodDialogState extends ConsumerState<_CreateFoodDialog> {
  late final _nameController = TextEditingController(text: widget.initialName);
  final _caloriesController = TextEditingController(text: '0');
  final _proteinsController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatsController = TextEditingController(text: '0');
  bool _isSubmitting = false;
  String? _errorMessage;

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
      final food = await ref.read(fridgeApiClientProvider).createCustomFood(
            groupId: widget.groupId,
            name: name,
            caloriesPer100g: double.tryParse(_caloriesController.text) ?? 0,
            proteinsPer100g: double.tryParse(_proteinsController.text) ?? 0,
            carbsPer100g: double.tryParse(_carbsController.text) ?? 0,
            fatsPer100g: double.tryParse(_fatsController.text) ?? 0,
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 8),
            const Text('Valeurs pour 100g :', style: TextStyle(fontSize: 12)),
            TextField(
              controller: _caloriesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Kcal'),
            ),
            TextField(
              controller: _proteinsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Protéines'),
            ),
            TextField(
              controller: _carbsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Glucides'),
            ),
            TextField(
              controller: _fatsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Lipides'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Créer'),
        ),
      ],
    );
  }
}
