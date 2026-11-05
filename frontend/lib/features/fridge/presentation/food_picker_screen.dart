import 'package:flutter/material.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/presentation/widgets/food_search_view.dart';

Future<FoodReference?> pickFood(
  BuildContext context, {
  required int groupId,
  bool startWithScan = false,
}) {
  return Navigator.of(context).push<FoodReference>(
    MaterialPageRoute(
      builder: (pickerContext) => Scaffold(
        appBar: AppBar(title: const Text('Choisir un aliment')),
        body: FoodSearchView(
          groupId: groupId,
          startWithScan: startWithScan,
          onSelected: (food) => Navigator.of(pickerContext).pop(food),
        ),
      ),
    ),
  );
}
