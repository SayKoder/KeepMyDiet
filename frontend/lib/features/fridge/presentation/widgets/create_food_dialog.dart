import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/dialog_action_buttons.dart';
import '../../../../shared/widgets/form_error_text.dart';
import '../../../../shared/widgets/number_field.dart';
import '../../../../shared/widgets/submit_button_content.dart';
import '../../data/fridge_api_client.dart';
import '../../data/open_food_facts_client.dart';
import '../../domain/food_reference.dart';
import '../fridge_controller.dart';

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
    builder: (_) => _CreateFoodDialog(
      groupId: groupId,
      initialName: product?.name ?? name,
      product: product,
      barcode: barcode,
    ),
  );
}

class _CreateFoodDialog extends ConsumerStatefulWidget {
  const _CreateFoodDialog({
    required this.groupId,
    required this.initialName,
    this.product,
    this.barcode,
  });

  final int groupId;
  final String initialName;
  final OpenFoodFactsProduct? product;
  final String? barcode;

  @override
  ConsumerState<_CreateFoodDialog> createState() => _CreateFoodDialogState();
}

class _CreateFoodDialogState extends ConsumerState<_CreateFoodDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _calories = _numberController(widget.product?.caloriesPer100g);
  late final _proteins = _numberController(widget.product?.proteinsPer100g);
  late final _carbs = _numberController(widget.product?.carbsPer100g);
  late final _fats = _numberController(widget.product?.fatsPer100g);
  bool _isSubmitting = false;
  String? _errorMessage;

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
      final food = await ref
          .read(fridgeApiClientProvider)
          .createCustomFood(
            groupId: widget.groupId,
            name: name,
            caloriesPer100g: _parse(_calories),
            proteinsPer100g: _parse(_proteins),
            carbsPer100g: _parse(_carbs),
            fatsPer100g: _parse(_fats),
            barcode: widget.barcode,
          );
      ref.invalidate(foodCatalogProvider(widget.groupId));
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

    return AlertDialog(
      title: const Text('Nouveau produit'),
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
          confirmLabel: 'Créer',
          onConfirm: _isSubmitting ? null : _submit,
          confirmChild: SubmitButtonContent(
            isSubmitting: _isSubmitting,
            label: const Text('Créer'),
            size: 16,
          ),
        ),
      ],
    );
  }
}
