import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/nutrition_api_client.dart';
import '../domain/water_intake.dart';

final waterIntakeControllerProvider =
    AsyncNotifierProvider<WaterIntakeController, WaterIntake?>(WaterIntakeController.new);

/// `null` = rien de bu enregistré aujourd'hui (pas une erreur, voir
/// `fetchTodayWaterIntake`). Observe la session comme `ProfileController` :
/// sinon le suivi de l'ancien compte resterait affiché après un changement
/// d'utilisateur.
class WaterIntakeController extends AsyncNotifier<WaterIntake?> {
  @override
  Future<WaterIntake?> build() {
    ref.watch(authControllerProvider);

    return ref.read(nutritionApiClientProvider).fetchTodayWaterIntake();
  }

  Future<void> add(int deltaMl) async {
    final intake = await ref.read(nutritionApiClientProvider).addWater(deltaMl);
    state = AsyncData(intake);
  }
}
