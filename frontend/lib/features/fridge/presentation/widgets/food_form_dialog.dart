import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';
import 'package:keepmydiet/features/fridge/domain/food_draft.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/presentation/fridge_controller.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

// `product` pré-remplit le formulaire (trouvé sur Open Food Facts),
// `barcode` est rattaché au produit pour le retrouver au prochain scan.
Future<FoodReference?> showCreateFoodDialog(
  BuildContext context, {
  required int groupId,
  String name = '',
  OpenFoodFactsProduct? product,
  String? barcode,
}) {
  return showDialog<FoodReference>(
    context: context,
    builder: (_) => _FoodFormDialog(
      groupId: groupId,
      initialName: product?.name ?? name,
      product: product,
      barcode: barcode,
    ),
  );
}

Future<FoodReference?> showEditFoodDialog(
  BuildContext context, {
  required int groupId,
  required FoodReference food,
}) {
  return showDialog<FoodReference>(
    context: context,
    builder: (_) => _FoodFormDialog(groupId: groupId, food: food),
  );
}

class _FoodFormDialog extends ConsumerStatefulWidget {
  const _FoodFormDialog({
    required this.groupId,
    this.food,
    this.initialName = '',
    this.product,
    this.barcode,
  });

  final int groupId;
  final FoodReference? food;
  final String initialName;
  final OpenFoodFactsProduct? product;
  final String? barcode;

  @override
  ConsumerState<_FoodFormDialog> createState() => _FoodFormDialogState();
}

class _FoodFormDialogState extends ConsumerState<_FoodFormDialog> {
  late final _name = TextEditingController(
    text: widget.food?.name ?? widget.initialName,
  );
  late final _calories = _numberController(
    widget.food?.caloriesPer100g ?? widget.product?.caloriesPer100g,
  );
  late final _proteins = _numberController(
    widget.food?.proteinsPer100g ?? widget.product?.proteinsPer100g,
  );
  late final _carbs = _numberController(
    widget.food?.carbsPer100g ?? widget.product?.carbsPer100g,
  );
  late final _fats = _numberController(
    widget.food?.fatsPer100g ?? widget.product?.fatsPer100g,
  );
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.food != null;

  static TextEditingController _numberController(double? value) =>
      TextEditingController(text: (value ?? 0).toString());

  static double _parse(TextEditingController controller) =>
      double.tryParse(controller.text) ?? 0;

  @override
  void dispose() {
    for (final controller in [_name, _calories, _proteins, _carbs, _fats]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? get _barcodeHint {
    final barcode = widget.barcode;
    if (barcode == null) return null;
    return widget.initialName.isEmpty
        ? 'Code-barres $barcode — introuvable sur Open Food Facts, à saisir manuellement'
        : 'Pré-rempli depuis Open Food Facts (code $barcode), vérifie avant de valider';
  }

  Future<FoodReference> _save(FoodDraft draft) {
    final food = widget.food;

    return food == null
        ? createCustomFood(ref, groupId: widget.groupId, draft: draft)
        : updateCustomFood(
            ref,
            groupId: widget.groupId,
            foodId: food.id,
            draft: draft,
          );
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Le nom ne peut pas être vide.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final food = await _save(
        FoodDraft(
          name: name,
          caloriesPer100g: _parse(_calories),
          proteinsPer100g: _parse(_proteins),
          carbsPer100g: _parse(_carbs),
          fatsPer100g: _parse(_fats),
          barcode: widget.barcode,
        ),
      );
      if (mounted) Navigator.of(context).pop(food);
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = _barcodeHint;
    final confirmLabel = _isEdit ? 'Enregistrer' : 'Créer';

    return AlertDialog(
      title: Text(_isEdit ? 'Modifier le produit' : 'Nouveau produit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            if (hint != null)
              Text(
                hint,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const Text('Valeurs pour 100g :', style: TextStyle(fontSize: 12)),
            NumberField(controller: _calories, label: 'Kcal'),
            NumberField(controller: _proteins, label: 'Protéines'),
            NumberField(controller: _carbs, label: 'Glucides'),
            NumberField(controller: _fats, label: 'Lipides'),
            if (_errorMessage != null)
              FormErrorText(_errorMessage!, padding: EdgeInsets.zero),
          ],
        ),
      ),
      actions: [
        DialogActionButtons(
          cancelLabel: 'Annuler',
          onCancel: _isSubmitting ? null : () => Navigator.of(context).pop(),
          confirmLabel: confirmLabel,
          onConfirm: _isSubmitting ? null : _submit,
          confirmChild: SubmitButtonContent(
            isSubmitting: _isSubmitting,
            label: Text(confirmLabel),
            size: 16,
          ),
        ),
      ],
    );
  }
}
