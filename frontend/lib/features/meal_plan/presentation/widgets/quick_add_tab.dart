import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/form_error_text.dart';
import '../../../../shared/widgets/number_field.dart';
import '../../../../shared/widgets/submit_button_content.dart';
import '../../../recipes/data/recipes_api_client.dart';
import '../../../recipes/domain/recipe_ingredient.dart';
import '../../../recipes/presentation/recipes_controller.dart';
import 'existing_recipe_tab.dart';

// "Ajout rapide" : crée en coulisses une recette sans étapes.
class QuickAddTab extends ConsumerStatefulWidget {
  const QuickAddTab({
    super.key,
    required this.defaultName,
    required this.saveEntry,
  });

  final String defaultName;
  final SaveMealEntry saveEntry;

  @override
  ConsumerState<QuickAddTab> createState() => _QuickAddTabState();
}

class _QuickAddTabState extends ConsumerState<QuickAddTab> {
  final _nameController = TextEditingController();
  final List<_IngredientRow> _rows = [_IngredientRow()];
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final ingredients = _rows.map((row) => row.toIngredientOrNull()).toList();
    if (ingredients.contains(null)) {
      setState(
        () => _error =
            "Chaque aliment a besoin d'un nom et d'une quantité positive.",
      );
      return;
    }

    final name = _nameController.text.trim();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final recipe = await ref
          .read(recipesControllerProvider.notifier)
          .create(
            name: name.isEmpty ? widget.defaultName : name,
            referenceServings: 1,
            ingredients: ingredients.cast<RecipeIngredient>(),
          );
      final entry = await widget.saveEntry(recipeId: recipe.id, servings: 1);
      if (mounted) Navigator.of(context).pop(entry);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom (facultatif)',
            hintText: 'Ex : Banane + jus de pomme',
          ),
        ),
        const SizedBox(height: 16),
        for (final row in _rows)
          _IngredientCard(
            key: ObjectKey(row),
            row: row,
            onRemove: _rows.length > 1
                ? () => setState(() => _rows.remove(row..dispose()))
                : null,
          ),
        TextButton.icon(
          onPressed: () => setState(() => _rows.add(_IngredientRow())),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un aliment'),
        ),
        const SizedBox(height: 16),
        if (_error != null) FormErrorText(_error!),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: SubmitButtonContent(
            isSubmitting: _isSubmitting,
            label: const Text('Ajouter au planning'),
          ),
        ),
      ],
    );
  }
}

class _IngredientRow {
  final name = TextEditingController();
  final quantity = TextEditingController();
  final unit = TextEditingController(text: 'g');
  final calories = TextEditingController(text: '0');
  final proteins = TextEditingController(text: '0');
  final carbs = TextEditingController(text: '0');
  final fats = TextEditingController(text: '0');

  List<TextEditingController> get _all => [
    name,
    quantity,
    unit,
    calories,
    proteins,
    carbs,
    fats,
  ];

  void dispose() {
    for (final controller in _all) {
      controller.dispose();
    }
  }

  void fill(RecipeIngredient ingredient) {
    name.text = ingredient.name;
    quantity.text = _format(ingredient.quantity);
    unit.text = ingredient.unit;
    calories.text = _format(ingredient.calories);
    proteins.text = _format(ingredient.proteins);
    carbs.text = _format(ingredient.carbs);
    fats.text = _format(ingredient.fats);
  }

  RecipeIngredient? toIngredientOrNull() {
    final quantityValue = double.tryParse(quantity.text);
    if (name.text.trim().isEmpty ||
        quantityValue == null ||
        quantityValue <= 0) {
      return null;
    }

    return RecipeIngredient(
      name: name.text.trim(),
      quantity: quantityValue,
      unit: unit.text.trim().isEmpty ? 'g' : unit.text.trim(),
      calories: double.tryParse(calories.text) ?? 0,
      proteins: double.tryParse(proteins.text) ?? 0,
      carbs: double.tryParse(carbs.text) ?? 0,
      fats: double.tryParse(fats.text) ?? 0,
    );
  }
}

String _format(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

class _IngredientCard extends ConsumerStatefulWidget {
  const _IngredientCard({super.key, required this.row, required this.onRemove});

  final _IngredientRow row;
  final VoidCallback? onRemove;

  @override
  ConsumerState<_IngredientCard> createState() => _IngredientCardState();
}

class _IngredientCardState extends ConsumerState<_IngredientCard> {
  Timer? _debounce;
  List<RecipeIngredient> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onNameChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await ref
          .read(recipesApiClientProvider)
          .suggestIngredients(query);
      if (mounted) setState(() => _suggestions = results);
    });
  }

  void _applySuggestion(RecipeIngredient suggestion) {
    widget.row.fill(suggestion);
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 8,
          children: [
            TextField(
              controller: row.name,
              onChanged: _onNameChanged,
              decoration: InputDecoration(
                labelText: 'Aliment',
                suffixIcon: widget.onRemove == null
                    ? null
                    : IconButton(
                        onPressed: widget.onRemove,
                        icon: const Icon(Icons.delete_outline),
                      ),
              ),
            ),
            if (_suggestions.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final suggestion in _suggestions)
                    ActionChip(
                      label: Text(
                        '${suggestion.name} '
                        '(${_format(suggestion.quantity)}${suggestion.unit})',
                      ),
                      onPressed: () => _applySuggestion(suggestion),
                    ),
                ],
              ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: NumberField(
                    controller: row.quantity,
                    label: 'Quantité',
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: row.unit,
                    decoration: const InputDecoration(labelText: 'Unité'),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: NumberField(controller: row.calories, label: 'Kcal'),
                ),
                Expanded(
                  child: NumberField(
                    controller: row.proteins,
                    label: 'Protéines',
                  ),
                ),
                Expanded(
                  child: NumberField(controller: row.carbs, label: 'Glucides'),
                ),
                Expanded(
                  child: NumberField(controller: row.fats, label: 'Lipides'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
