import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe_ingredient.dart';
import 'recipes_controller.dart';

class CreateRecipeScreen extends ConsumerStatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  ConsumerState<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

/// Un ingrédient du formulaire = un groupe de `TextEditingController`, un par
/// champ. Regroupés dans une petite classe pour ne pas jongler avec 7 listes
/// parallèles — et pour pouvoir tous les `dispose()` d'un coup.
class _IngredientRow {
  _IngredientRow()
      : name = TextEditingController(),
        quantity = TextEditingController(),
        unit = TextEditingController(text: 'g'),
        calories = TextEditingController(text: '0'),
        proteins = TextEditingController(text: '0'),
        carbs = TextEditingController(text: '0'),
        fats = TextEditingController(text: '0');

  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unit;
  final TextEditingController calories;
  final TextEditingController proteins;
  final TextEditingController carbs;
  final TextEditingController fats;

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
    calories.dispose();
    proteins.dispose();
    carbs.dispose();
    fats.dispose();
  }

  /// `null` si un champ obligatoire est vide/invalide — le retour direct d'un
  /// `RecipeIngredient?` évite de dupliquer la validation entre le parsing et
  /// le message d'erreur affiché à l'utilisateur.
  RecipeIngredient? toIngredientOrNull() {
    final quantityValue = double.tryParse(quantity.text);
    if (name.text.trim().isEmpty || quantityValue == null || quantityValue <= 0) {
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

class _CreateRecipeScreenState extends ConsumerState<CreateRecipeScreen> {
  final _nameController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');
  final List<_IngredientRow> _ingredientRows = [_IngredientRow()];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _servingsController.dispose();
    for (final row in _ingredientRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addIngredientRow() {
    setState(() => _ingredientRows.add(_IngredientRow()));
  }

  void _removeIngredientRow(int index) {
    setState(() => _ingredientRows.removeAt(index).dispose());
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final servings = int.tryParse(_servingsController.text);

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Le nom ne peut pas être vide.');
      return;
    }
    if (servings == null || servings <= 0) {
      setState(() => _errorMessage = 'Le nombre de personnes doit être positif.');
      return;
    }

    final ingredients = _ingredientRows.map((row) => row.toIngredientOrNull()).toList();
    if (ingredients.isEmpty || ingredients.any((i) => i == null)) {
      setState(() => _errorMessage =
          'Chaque ingrédient a besoin d\'un nom et d\'une quantité positive.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(recipesControllerProvider.notifier).create(
            name: name,
            referenceServings: servings,
            ingredients: ingredients.cast<RecipeIngredient>(),
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
      appBar: AppBar(title: const Text('Nouvelle recette')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nom de la recette'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _servingsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nombre de personnes'),
          ),
          const SizedBox(height: 24),
          Text('Ingrédients', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _ingredientRows.length; i++)
            _IngredientForm(
              row: _ingredientRows[i],
              onRemove: _ingredientRows.length > 1 ? () => _removeIngredientRow(i) : null,
            ),
          TextButton.icon(
            onPressed: _addIngredientRow,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un ingrédient'),
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer la recette'),
          ),
        ],
      ),
    );
  }
}

/// Une carte par ingrédient : nom + quantité/unité sur une ligne, macros sur
/// une autre. Widget à part pour ne pas alourdir `build()` du parent.
class _IngredientForm extends StatelessWidget {
  const _IngredientForm({required this.row, required this.onRemove});

  final _IngredientRow row;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.name,
                    decoration: const InputDecoration(labelText: 'Ingrédient'),
                  ),
                ),
                if (onRemove != null)
                  IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.quantity,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantité'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.unit,
                    decoration: const InputDecoration(labelText: 'Unité'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.calories,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Kcal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.proteins,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Protéines'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.carbs,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Glucides'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.fats,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Lipides'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
