import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/auth/presentation/auth_controller.dart';
import 'package:keepmydiet/features/home/presentation/journal_date_controller.dart';
import 'package:keepmydiet/features/nutrition/data/nutrition_repository.dart';
import 'package:keepmydiet/features/nutrition/domain/water_intake.dart';

final waterIntakeControllerProvider =
    AsyncNotifierProvider<WaterIntakeController, WaterIntake?>(
      WaterIntakeController.new,
    );

/// `null` = rien de bu enregistré ce jour-là (pas une erreur, voir
/// `fetchWaterIntakeForDate`). Observe la session comme avant, ET le jour
/// affiché (journalDateProvider) : changer de jour via les chevrons
/// redéclenche un fetch pour la nouvelle date.
class WaterIntakeController extends AsyncNotifier<WaterIntake?> {
  @override
  Future<WaterIntake?> build() {
    ref.watch(authControllerProvider);
    final date = ref.watch(journalDateProvider);

    return ref.read(nutritionRepositoryProvider).fetchWaterIntakeForDate(date);
  }

  Future<void> add(int deltaMl) async {
    final date = ref.read(journalDateProvider);
    final intake = await ref
        .read(nutritionRepositoryProvider)
        .addWater(deltaMl, date: date);
    state = AsyncData(intake);
  }
}
