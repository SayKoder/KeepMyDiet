import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/domain/storage_location.dart';
import 'package:keepmydiet/features/fridge/presentation/fridge_controller.dart';
import 'package:keepmydiet/features/fridge/presentation/widgets/food_search_view.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

// Étape 1 : choisir l'aliment. Étape 2 : quantité, lieu et date.
class AddFridgeItemScreen extends StatefulWidget {
  const AddFridgeItemScreen({
    super.key,
    required this.groupId,
    required this.defaultLocation,
  });

  final int groupId;
  final StorageLocation defaultLocation;

  @override
  State<AddFridgeItemScreen> createState() => _AddFridgeItemScreenState();
}

class _AddFridgeItemScreenState extends State<AddFridgeItemScreen> {
  FoodReference? _selectedFood;

  @override
  Widget build(BuildContext context) {
    final food = _selectedFood;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un aliment')),
      body: food == null
          ? FoodSearchView(
              groupId: widget.groupId,
              onSelected: (food) => setState(() => _selectedFood = food),
            )
          : _ItemDetailsForm(
              groupId: widget.groupId,
              food: food,
              defaultLocation: widget.defaultLocation,
              onChangeFood: () => setState(() => _selectedFood = null),
            ),
    );
  }
}

class _ItemDetailsForm extends ConsumerStatefulWidget {
  const _ItemDetailsForm({
    required this.groupId,
    required this.food,
    required this.defaultLocation,
    required this.onChangeFood,
  });

  final int groupId;
  final FoodReference food;
  final StorageLocation defaultLocation;
  final VoidCallback onChangeFood;

  @override
  ConsumerState<_ItemDetailsForm> createState() => _ItemDetailsFormState();
}

class _ItemDetailsFormState extends ConsumerState<_ItemDetailsForm> {
  final _quantityController = TextEditingController(text: '100');
  final _unitController = TextEditingController(text: 'g');
  late StorageLocation _location = widget.defaultLocation;
  DateTime? _expirationDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
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
    if (picked != null) setState(() => _expirationDate = picked);
  }

  String? _validate(double? quantity, String unit) {
    if (quantity == null || quantity <= 0 || unit.isEmpty) {
      return 'Quantité et unité invalides.';
    }
    if (_expirationDate == null) return 'Choisis une date de péremption.';
    return null;
  }

  Future<void> _submit() async {
    final quantity = double.tryParse(_quantityController.text);
    final unit = _unitController.text.trim();
    final error = _validate(quantity, unit);

    setState(() {
      _errorMessage = error;
      _isSubmitting = error == null;
    });
    if (error != null) return;

    try {
      await addFridgeItem(
        ref,
        groupId: widget.groupId,
        foodReferenceId: widget.food.id,
        storageLocation: _location,
        quantity: quantity!,
        unit: unit,
        expirationDate: _expirationDate!,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = _expirationDate;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text(widget.food.name),
            subtitle: Text(
              '${widget.food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
            ),
            trailing: TextButton(
              onPressed: widget.onChangeFood,
              child: const Text('Changer'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          spacing: 8,
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
            Expanded(child: IngredientUnitField(controller: _unitController)),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<StorageLocation>(
          segments: [
            for (final location in StorageLocation.values)
              ButtonSegment(value: location, label: Text(location.label)),
          ],
          selected: {_location},
          onSelectionChanged: (selection) =>
              setState(() => _location = selection.first),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Date de péremption'),
          subtitle: Text(
            date == null ? 'Non renseignée' : DateFormat('d/M/y').format(date),
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
