import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/recipes/domain/recipe.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_draft.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_ingredient.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_step.dart';
import 'package:keepmydiet/features/recipes/presentation/recipes_controller.dart';
import 'package:keepmydiet/features/recipes/presentation/widgets/ingredient_form_card.dart';
import 'package:keepmydiet/features/recipes/presentation/widgets/step_form_card.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

/// Crée une recette, ou modifie `recipe` si elle est fournie (formulaire
/// pré-rempli ; les ingrédients et étapes envoyés remplacent les anciens).
class RecipeFormScreen extends ConsumerStatefulWidget {
  const RecipeFormScreen({super.key, this.recipe});

  final Recipe? recipe;

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  late final _nameController = TextEditingController(text: widget.recipe?.name);
  late final _servingsController = TextEditingController(
    text: '${widget.recipe?.referenceServings ?? 4}',
  );
  late final List<IngredientFormRow> _ingredients =
      widget.recipe?.ingredients
          .map((ingredient) => IngredientFormRow()..fill(ingredient))
          .toList() ??
      [IngredientFormRow()];
  late final List<StepFormRow> _steps =
      widget.recipe?.steps.map((step) => StepFormRow()..fill(step)).toList() ??
      [];
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.recipe != null;

  @override
  void dispose() {
    _nameController.dispose();
    _servingsController.dispose();
    for (final row in _ingredients) {
      row.dispose();
    }
    for (final row in _steps) {
      row.dispose();
    }
    super.dispose();
  }

  String? _validate(
    String name,
    int? servings,
    List<RecipeIngredient?> ingredients,
  ) {
    if (name.isEmpty) return 'Le nom ne peut pas être vide.';
    if (servings == null || servings <= 0) {
      return 'Le nombre de personnes doit être positif.';
    }
    if (ingredients.contains(null)) {
      return "Chaque ingrédient a besoin d'un nom et d'une quantité positive.";
    }
    return null;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final servings = int.tryParse(_servingsController.text);
    final ingredients = [
      for (final row in _ingredients) row.toIngredientOrNull(),
    ];
    final steps = _steps
        .map((row) => row.toStepOrNull())
        .whereType<RecipeStep>()
        .toList();

    final error = _validate(name, servings, ingredients);
    setState(() {
      _errorMessage = error;
      _isSubmitting = error == null;
    });
    if (error != null) return;

    final draft = RecipeDraft(
      name: name,
      referenceServings: servings!,
      ingredients: ingredients.cast<RecipeIngredient>(),
      steps: steps,
    );
    final controller = ref.read(recipesControllerProvider.notifier);
    final recipe = widget.recipe;

    try {
      await (recipe == null
          ? controller.create(draft)
          : controller.updateRecipe(recipe.id, draft));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitle = Theme.of(context).textTheme.titleLarge;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              spacing: 12,
              children: [
                const RoundBackButton(),
                Expanded(
                  child: Text(
                    _isEdit ? 'Modifier la recette' : 'Nouvelle recette',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Text('INFOS', style: Theme.of(context).textTheme.labelSmall),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la recette',
                    ),
                  ),
                  NumberField(
                    controller: _servingsController,
                    label: 'Nombre de personnes',
                    decimal: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Ingrédients', style: sectionTitle),
            const SizedBox(height: 12),
            for (var i = 0; i < _ingredients.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IngredientFormCard(
                  key: ObjectKey(_ingredients[i]),
                  number: i + 1,
                  row: _ingredients[i],
                  onRemove: _ingredients.length > 1
                      ? () => setState(() => _ingredients.removeAt(i).dispose())
                      : null,
                ),
              ),
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _ingredients.add(IngredientFormRow())),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un ingrédient'),
            ),
            const SizedBox(height: 24),
            Text('Préparation (facultatif)', style: sectionTitle),
            const SizedBox(height: 12),
            for (var i = 0; i < _steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StepFormCard(
                  key: ObjectKey(_steps[i]),
                  number: i + 1,
                  row: _steps[i],
                  onRemove: () => setState(() => _steps.removeAt(i).dispose()),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _steps.add(StepFormRow())),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une étape'),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              MessageBanner.error(message: _errorMessage!),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: SubmitButtonContent(
                isSubmitting: _isSubmitting,
                label: Text(_isEdit ? 'Enregistrer' : 'Créer la recette'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
