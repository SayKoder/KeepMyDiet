import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/form_error_text.dart';
import '../../../shared/ingredient_unit_field.dart';
import '../../../shared/submit_button_content.dart';
import '../data/recipes_api_client.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_step.dart';
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

/// Une étape du formulaire, facultative : la liste peut rester vide (pas de
/// `Assert\Count` côté backend, contrairement aux ingrédients).
class _StepRow {
  _StepRow()
    : instruction = TextEditingController(),
      durationMinutes = TextEditingController();

  final TextEditingController instruction;
  final TextEditingController durationMinutes;

  void dispose() {
    instruction.dispose();
    durationMinutes.dispose();
  }

  /// `null` si le texte est vide — une étape sans instruction n'a pas de sens
  /// et est simplement ignorée plutôt que de bloquer la soumission (étapes
  /// facultatives : pas besoin d'un message d'erreur pour une ligne vide
  /// qu'on a juste oublié de retirer).
  RecipeStep? toStepOrNull() {
    final text = instruction.text.trim();
    if (text.isEmpty) {
      return null;
    }

    return RecipeStep(
      instruction: text,
      durationMinutes: int.tryParse(durationMinutes.text.trim()),
    );
  }
}

class _CreateRecipeScreenState extends ConsumerState<CreateRecipeScreen> {
  final _nameController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');
  final List<_IngredientRow> _ingredientRows = [_IngredientRow()];
  final List<_StepRow> _stepRows = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _servingsController.dispose();
    for (final row in _ingredientRows) {
      row.dispose();
    }
    for (final row in _stepRows) {
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

  void _addStepRow() {
    setState(() => _stepRows.add(_StepRow()));
  }

  void _removeStepRow(int index) {
    setState(() => _stepRows.removeAt(index).dispose());
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final servings = int.tryParse(_servingsController.text);

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Le nom ne peut pas être vide.');
      return;
    }
    if (servings == null || servings <= 0) {
      setState(
        () => _errorMessage = 'Le nombre de personnes doit être positif.',
      );
      return;
    }

    final ingredients = _ingredientRows
        .map((row) => row.toIngredientOrNull())
        .toList();
    if (ingredients.isEmpty || ingredients.any((i) => i == null)) {
      setState(
        () => _errorMessage =
            'Chaque ingrédient a besoin d\'un nom et d\'une quantité positive.',
      );
      return;
    }

    // Lignes d'étape vides silencieusement ignorées (voir _StepRow.toStepOrNull).
    final steps = _stepRows
        .map((row) => row.toStepOrNull())
        .whereType<RecipeStep>()
        .toList();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(recipesControllerProvider.notifier)
          .create(
            name: name,
            referenceServings: servings,
            ingredients: ingredients.cast<RecipeIngredient>(),
            steps: steps,
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
              onRemove: _ingredientRows.length > 1
                  ? () => _removeIngredientRow(i)
                  : null,
            ),
          TextButton.icon(
            onPressed: _addIngredientRow,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un ingrédient'),
          ),
          const SizedBox(height: 24),
          Text(
            'Étapes de préparation (facultatif)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _stepRows.length; i++)
            _StepForm(
              index: i,
              row: _stepRows[i],
              onRemove: () => _removeStepRow(i),
            ),
          TextButton.icon(
            onPressed: _addStepRow,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une étape'),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null) FormErrorText(_errorMessage!),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: SubmitButtonContent(
              isSubmitting: _isSubmitting,
              label: const Text('Créer la recette'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une carte par ingrédient : nom + quantité/unité sur une ligne, macros sur
/// une autre. `ConsumerStatefulWidget` (pas `StatelessWidget`) parce qu'il
/// porte son propre debounce + ses propres suggestions d'autocomplete, sans
/// remonter cet état éphémère jusqu'au formulaire parent.
class _IngredientForm extends ConsumerStatefulWidget {
  const _IngredientForm({required this.row, required this.onRemove});

  final _IngredientRow row;
  final VoidCallback? onRemove;

  @override
  ConsumerState<_IngredientForm> createState() => _IngredientFormState();
}

class _IngredientFormState extends ConsumerState<_IngredientForm> {
  Timer? _debounce;
  List<RecipeIngredient> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Débounce de 300ms : évite une requête à chaque frappe, le temps que
  /// l'utilisateur finisse de taper. Sous 2 caractères, le backend renvoie
  /// de toute façon une liste vide (voir IngredientSuggestionsProvider).
  void _onNameChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await ref
          .read(recipesApiClientProvider)
          .suggestIngredients(value.trim());
      if (mounted) {
        setState(() => _suggestions = results);
      }
    });
  }

  /// Reprend tel quel l'exemple choisi (pas de recalcul au prorata d'une
  /// quantité différente : l'utilisateur peut ajuster la quantité à la main,
  /// au prix de macros à revérifier s'il change beaucoup — mise à l'échelle
  /// automatique volontairement hors scope pour cette première version).
  void _applySuggestion(RecipeIngredient suggestion) {
    widget.row.name.text = suggestion.name;
    widget.row.quantity.text = _formatNumber(suggestion.quantity);
    widget.row.unit.text = suggestion.unit;
    widget.row.calories.text = _formatNumber(suggestion.calories);
    widget.row.proteins.text = _formatNumber(suggestion.proteins);
    widget.row.carbs.text = _formatNumber(suggestion.carbs);
    widget.row.fats.text = _formatNumber(suggestion.fats);
    setState(() => _suggestions = []);
  }

  String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  @override
  Widget build(BuildContext context) {
    final row = widget.row;

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
                    onChanged: _onNameChanged,
                    decoration: const InputDecoration(labelText: 'Ingrédient'),
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            if (_suggestions.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _suggestions
                        .map(
                          (s) => ActionChip(
                            label: Text(
                              '${s.name} (${_formatNumber(s.quantity)}${s.unit})',
                            ),
                            onPressed: () => _applySuggestion(s),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Quantité'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: IngredientUnitField(controller: row.unit)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.calories,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Kcal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.proteins,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Protéines'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.carbs,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Glucides'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.fats,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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

/// Une carte par étape : numéro (juste l'index, pas éditable — l'ordre suit
/// l'ordre des cartes), texte de l'instruction, durée facultative.
class _StepForm extends StatelessWidget {
  const _StepForm({
    required this.index,
    required this.row,
    required this.onRemove,
  });

  final int index;
  final _StepRow row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 14, child: Text('${index + 1}')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: row.instruction,
                    maxLines: null,
                    decoration: const InputDecoration(labelText: 'Instruction'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: row.durationMinutes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Durée (minutes) — optionnel',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
