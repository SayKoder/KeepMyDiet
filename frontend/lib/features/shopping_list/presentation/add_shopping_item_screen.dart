import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/presentation/widgets/food_search_view.dart';
import 'package:keepmydiet/features/shopping_list/presentation/shopping_list_controller.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class AddShoppingItemScreen extends StatefulWidget {
  const AddShoppingItemScreen({super.key, required this.groupId});

  final int groupId;

  @override
  State<AddShoppingItemScreen> createState() => _AddShoppingItemScreenState();
}

class _AddShoppingItemScreenState extends State<AddShoppingItemScreen> {
  FoodReference? _selectedFood;

  @override
  Widget build(BuildContext context) {
    final food = _selectedFood;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter à la liste')),
      body: food == null
          ? FoodSearchView(
              groupId: widget.groupId,
              onSelected: (food) => setState(() => _selectedFood = food),
            )
          : _QuantityForm(
              groupId: widget.groupId,
              food: food,
              onChangeFood: () => setState(() => _selectedFood = null),
            ),
    );
  }
}

class _QuantityForm extends ConsumerStatefulWidget {
  const _QuantityForm({
    required this.groupId,
    required this.food,
    required this.onChangeFood,
  });

  final int groupId;
  final FoodReference food;
  final VoidCallback onChangeFood;

  @override
  ConsumerState<_QuantityForm> createState() => _QuantityFormState();
}

class _QuantityFormState extends ConsumerState<_QuantityForm> {
  final _quantityController = TextEditingController(text: '100');
  final _unitController = TextEditingController(text: 'g');
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = double.tryParse(_quantityController.text);
    final unit = _unitController.text.trim();
    if (quantity == null || quantity <= 0 || unit.isEmpty) {
      setState(() => _errorMessage = 'Quantité et unité invalides.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });
    final food = widget.food;
    try {
      await addShoppingListItem(
        ref,
        groupId: widget.groupId,
        name: food.name,
        quantity: quantity,
        unit: unit,
        caloriesPer100g: food.caloriesPer100g,
        proteinsPer100g: food.proteinsPer100g,
        carbsPer100g: food.carbsPer100g,
        fatsPer100g: food.fatsPer100g,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        QuantityUnitRow(
          quantityController: _quantityController,
          unitController: _unitController,
        ),
        const SizedBox(height: 16),
        if (_errorMessage != null) FormErrorText(_errorMessage!),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: SubmitButtonContent(
            isSubmitting: _isSubmitting,
            label: const Text('Ajouter à la liste'),
          ),
        ),
      ],
    );
  }
}
