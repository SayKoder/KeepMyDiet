import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepmydiet/shared/widgets/live_refresh.dart';

void main() {
  testWidgets('rafraîchit à chaque intervalle puis s\'arrête à la fermeture', (
    tester,
  ) async {
    var ticks = 0;
    await tester.pumpWidget(
      LiveRefresh(
        interval: const Duration(seconds: 10),
        onRefresh: () => ticks++,
        child: const SizedBox(),
      ),
    );

    await tester.pump(const Duration(seconds: 25));
    expect(ticks, 2);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
    expect(ticks, 2);
  });

  testWidgets('ne rafraîchit pas quand l\'écran est masqué', (tester) async {
    var ticks = 0;
    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        child: LiveRefresh(
          interval: const Duration(seconds: 10),
          onRefresh: () => ticks++,
          child: const SizedBox(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 30));
    expect(ticks, 0);
  });
}
