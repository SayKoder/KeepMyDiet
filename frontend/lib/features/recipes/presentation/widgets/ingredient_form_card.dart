import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/recipes/data/recipes_repository.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_ingredient.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

// Les champs d'un ingrédient du formulaire.
class IngredientFormRow {
  final name = TextEditingController();
  final quantity = TextEditingController();
  final unit = TextEditingController(text: 'g');
  final calories = TextEditingController(text: '0');
  final proteins = TextEditingController(text: '0');
  final carbs = TextEditingController(text: '0');
  final fats = TextEditingController(text: '0');

  void dispose() {
    for (final controller in [
      name,
      quantity,
      unit,
      calories,
      proteins,
      carbs,
      fats,
    ]) {
      controller.dispose();
    }
  }

  void fill(RecipeIngredient ingredient) {
    name.text = ingredient.name;
    quantity.text = formatNumber(ingredient.quantity);
    unit.text = ingredient.unit;
    calories.text = formatNumber(ingredient.calories);
    proteins.text = formatNumber(ingredient.proteins);
    carbs.text = formatNumber(ingredient.carbs);
    fats.text = formatNumber(ingredient.fats);
  }

  // null si le nom est vide ou la quantité invalide.
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

String formatNumber(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

class IngredientFormCard extends ConsumerStatefulWidget {
  const IngredientFormCard({
    super.key,
    required this.number,
    required this.row,
    required this.onRemove,
  });

  final int number;
  final IngredientFormRow row;
  final VoidCallback? onRemove;

  @override
  ConsumerState<IngredientFormCard> createState() => _IngredientFormCardState();
}

class _IngredientFormCardState extends ConsumerState<IngredientFormCard> {
  Timer? _debounce;
  List<RecipeIngredient> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Attend 300 ms sans frappe avant de chercher des suggestions, et ignore
  // une réponse arrivée après que le texte a encore changé.
  void _onNameChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await ref
          .read(recipesRepositoryProvider)
          .suggestIngredients(query);
      if (!mounted || widget.row.name.text.trim() != query) return;
      setState(() => _suggestions = results);
    });
  }

  void _applySuggestion(RecipeIngredient suggestion) {
    widget.row.fill(suggestion);
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;

    return WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'INGRÉDIENT ${widget.number}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.errorText,
                  tooltip: 'Retirer',
                ),
            ],
          ),
          TextField(
            controller: row.name,
            onChanged: _onNameChanged,
            decoration: const InputDecoration(labelText: 'Ingrédient'),
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
                      '(${formatNumber(suggestion.quantity)}${suggestion.unit})',
                    ),
                    onPressed: () => _applySuggestion(suggestion),
                  ),
              ],
            ),
          QuantityUnitRow(
            quantityController: row.quantity,
            unitController: row.unit,
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: NumberField(controller: row.calories, label: 'Kcal'),
              ),
              Expanded(
                child: NumberField(controller: row.proteins, label: 'Prot.'),
              ),
              Expanded(
                child: NumberField(controller: row.carbs, label: 'Gluc.'),
              ),
              Expanded(
                child: NumberField(controller: row.fats, label: 'Lip.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
