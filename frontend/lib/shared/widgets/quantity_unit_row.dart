import 'package:flutter/material.dart';
import 'package:keepmydiet/shared/widgets/ingredient_unit_field.dart';
import 'package:keepmydiet/shared/widgets/number_field.dart';

class QuantityUnitRow extends StatelessWidget {
  const QuantityUnitRow({
    super.key,
    required this.quantityController,
    required this.unitController,
  });

  final TextEditingController quantityController;
  final TextEditingController unitController;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: NumberField(controller: quantityController, label: 'Quantité'),
        ),
        Expanded(child: IngredientUnitField(controller: unitController)),
      ],
    );
  }
}
