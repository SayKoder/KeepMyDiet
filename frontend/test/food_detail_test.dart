import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepmydiet/features/shopping_list/domain/shopping_list_item.dart';
import 'package:keepmydiet/features/shopping_list/presentation/widgets/shopping_item_group.dart';

import 'support/harness.dart';

void main() {
  testWidgets('liste de courses : la case coche, le nom ouvre le détail', (
    tester,
  ) async {
    final toggled = <int>[];
    await pumpScreen(
      tester,
      Scaffold(
        body: ShoppingItemGroup(
          title: 'Autres',
          items: const [
            ShoppingListItem(
              id: 3,
              name: 'Lait',
              quantity: 1,
              unit: 'L',
              caloriesPer100g: 46,
              proteinsPer100g: 3.4,
              carbsPer100g: 4.8,
              fatsPer100g: 1.6,
              sourceRecipeName: null,
            ),
          ],
          selectedIds: const {},
          onToggle: toggled.add,
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    expect(toggled, [3]);
    expect(find.text('46 kcal / 100g'), findsNothing);

    await tester.tap(find.text('Lait'));
    await tester.pumpAndSettle();
    expect(toggled, [3]);
    expect(find.text('46 kcal / 100g'), findsOneWidget);
    expect(find.text('Protéines 3.4 g'), findsOneWidget);
    await disposeScreen(tester);
  });
}
