import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/nutrition_api_client.dart';
import '../domain/water_goal.dart';

final waterGoalControllerProvider =
    AsyncNotifierProvider<WaterGoalController, WaterGoal?>(
      WaterGoalController.new,
    );

/// `null` = pas de surcharge d'objectif (le client utilise son calcul par
/// défaut). Observe la session comme `ProfileController`.
class WaterGoalController extends AsyncNotifier<WaterGoal?> {
  @override
  Future<WaterGoal?> build() {
    ref.watch(authControllerProvider);

    return ref.read(nutritionApiClientProvider).fetchMyWaterGoal();
  }

  Future<void> set(int goalMl) async {
    final goal = await ref
        .read(nutritionApiClientProvider)
        .setWaterGoal(goalMl);
    state = AsyncData(goal);
  }

  Future<void> reset() async {
    await ref.read(nutritionApiClientProvider).resetWaterGoal();
    state = const AsyncData(null);
  }
}
