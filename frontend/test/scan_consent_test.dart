import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepmydiet/features/fridge/presentation/barcode_scanner_screen.dart';

import 'support/harness.dart';

void main() {
  testWidgets(
    'le scan demande l\'accord à chaque ouverture, refus = pas de caméra',
    (tester) async {
      var results = <String?>[];
      await pumpScreen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => results.add(await scanBarcode(context)),
              child: const Text('scan'),
            ),
          ),
        ),
      );

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('scan'));
        await tester.pumpAndSettle();
        expect(find.text('Utiliser la caméra ?'), findsOneWidget);
        await tester.tap(find.text('Refuser'));
        await tester.pumpAndSettle();
      }

      expect(results, [null, null]);
      expect(find.text('Scanner un code-barres'), findsNothing);
      await disposeScreen(tester);
    },
  );
}
