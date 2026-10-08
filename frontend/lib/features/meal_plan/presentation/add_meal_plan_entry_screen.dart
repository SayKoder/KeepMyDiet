import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recipes/data/recipes_api_client.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/domain/recipe_ingredient.dart';
import '../../recipes/presentation/recipes_controller.dart';
import '../domain/meal_type.dart';
import 'meal_plan_controller.dart';

/// Deux façons d'alimenter un créneau : choisir une recette existante, ou un
/// "ajout rapide" (banane + jus de pomme...) qui crée une recette sans étapes
/// en coulisses via l'endpoint `POST /recipes` existant — pas de second
/// modèle de données, juste un formulaire plus court (décision actée avec
/// Carl le 2026-10-07, voir JOURNAL.md).
class AddMealPlanEntryScreen extends ConsumerStatefulWidget {
  const AddMealPlanEntryScreen({
    super.key,
    required this.groupId,
    required this.date,
    required this.mealType,
  });

  final int groupId;
  final DateTime date;
  final MealType mealType;

  @override
  ConsumerState<AddMealPlanEntryScreen> createState() => _AddMealPlanEntryScreenState();
}

class _AddMealPlanEntryScreenState extends ConsumerState<AddMealPlanEntryScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  Recipe? _selectedRecipe;
  final _servingsController = TextEditingController(text: '1');
  final _filterController = TextEditingController();
  String _filter = '';

  final _quickNameController = TextEditingController();
  final List<_IngredientRow> _quickIngredientRows = [_IngredientRow()];

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _tabController.dispose();
    _servingsController.dispose();
    _filterController.dispose();
    _quickNameController.dispose();
    for (final row in _quickIngredientRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _submitExisting() async {
    final recipe = _selectedRecipe;
    final servings = int.tryParse(_servingsController.text);

    if (recipe == null) {
      setState(() => _error = 'Choisis une recette dans la liste.');
      return;
    }
    if (servings == null || servings <= 0) {
      setState(() => _error = 'Le nombre de portions doit être positif.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(mealPlanControllerProvider).addEntry(
            groupId: widget.groupId,
            date: widget.date,
            mealType: widget.mealType,
            recipeId: recipe.id,
            servings: servings,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitQuickAdd() async {
    final ingredients = _quickIngredientRows.map((row) => row.toIngredientOrNull()).toList();
    if (ingredients.isEmpty || ingredients.any((i) => i == null)) {
      setState(() => _error = "Chaque aliment a besoin d'un nom et d'une quantité positive.");
      return;
    }

    final name = _quickNameController.text.trim().isEmpty
        ? '${widget.mealType.label} du ${widget.date.day}/${widget.date.month}'
        : _quickNameController.text.trim();

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final recipe = await ref.read(recipesControllerProvider.notifier).create(
            name: name,
            referenceServings: 1,
            ingredients: ingredients.cast<RecipeIngredient>(),
          );
      await ref.read(mealPlanControllerProvider).addEntry(
            groupId: widget.groupId,
            date: widget.date,
            mealType: widget.mealType,
            recipeId: recipe.id,
            servings: 1,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _addQuickIngredientRow() {
    setState(() => _quickIngredientRows.add(_IngredientRow()));
  }

  void _removeQuickIngredientRow(int index) {
    setState(() => _quickIngredientRows.removeAt(index).dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mealType.label} — ${widget.date.day}/${widget.date.month}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Recette existante'), Tab(text: 'Ajout rapide')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExistingTab(),
          _buildQuickAddTab(),
        ],
      ),
    );
  }

  Widget _buildExistingTab() {
    final recipesAsync = ref.watch(recipesControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _filterController,
            onChanged: (value) => setState(() => _filter = value.trim().toLowerCase()),
            decoration: const InputDecoration(
              labelText: 'Rechercher une recette',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: recipesAsync.when(
            data: (recipes) {
              final filtered = _filter.isEmpty
                  ? recipes
                  : recipes.where((r) => r.name.toLowerCase().contains(_filter)).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('Aucune recette ne correspond.'));
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final recipe = filtered[index];
                  final isSelected = _selectedRecipe?.id == recipe.id;
                  return ListTile(
                    selected: isSelected,
                    onTap: () => setState(() => _selectedRecipe = recipe),
                    leading: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined),
                    title: Text(recipe.name),
                    subtitle: Text(
                      '${recipe.totalCalories.toStringAsFixed(0)} kcal pour ${recipe.referenceServings} pers.',
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erreur : $error')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _servingsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nombre de portions prévues'),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              FilledButton(
                onPressed: _isSubmitting ? null : _submitExisting,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ajouter au planning'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _quickNameController,
          decoration: const InputDecoration(
            labelText: 'Nom (facultatif)',
            hintText: 'Ex : Banane + jus de pomme',
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _quickIngredientRows.length; i++)
          _QuickIngredientForm(
            row: _quickIngredientRows[i],
            onRemove: _quickIngredientRows.length > 1 ? () => _removeQuickIngredientRow(i) : null,
          ),
        TextButton.icon(
          onPressed: _addQuickIngredientRow,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un aliment'),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitQuickAdd,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Ajouter au planning'),
        ),
      ],
    );
  }
}

/// Même rôle que `_IngredientRow` de `create_recipe_screen.dart`, dupliqué
/// ici plutôt que partagé : les deux formulaires sont assez différents dans
/// le contexte (pas de nombre de personnes ici, nom de recette facultatif)
/// pour qu'une abstraction commune ajoute plus de complexité qu'elle n'en
/// retire.
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

class _QuickIngredientForm extends ConsumerStatefulWidget {
  const _QuickIngredientForm({required this.row, required this.onRemove});

  final _IngredientRow row;
  final VoidCallback? onRemove;

  @override
  ConsumerState<_QuickIngredientForm> createState() => _QuickIngredientFormState();
}

class _QuickIngredientFormState extends ConsumerState<_QuickIngredientForm> {
  Timer? _debounce;
  List<RecipeIngredient> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onNameChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await ref.read(recipesApiClientProvider).suggestIngredients(value.trim());
      if (mounted) {
        setState(() => _suggestions = results);
      }
    });
  }

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

  String _formatNumber(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

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
                    decoration: const InputDecoration(labelText: 'Aliment'),
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline)),
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
                        .map((s) => ActionChip(
                              label: Text('${s.name} (${_formatNumber(s.quantity)}${s.unit})'),
                              onPressed: () => _applySuggestion(s),
                            ))
                        .toList(),
                  ),
                ),
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
