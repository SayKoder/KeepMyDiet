import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/journal_date_controller.dart';
import '../data/nutrition_api_client.dart';
import '../domain/daily_nutrition_log.dart';

final dailyNutritionLogControllerProvider =
    AsyncNotifierProvider<DailyNutritionLogController, DailyNutritionLog?>(
      DailyNutritionLogController.new,
    );

/// `null` = rien consommé enregistré ce jour-là (pas une erreur). Observe la
/// session (comme WaterIntakeController) ET le jour affiché
/// (journalDateProvider) : changer de jour via les chevrons redéclenche un
/// fetch pour la nouvelle date.
class DailyNutritionLogController extends AsyncNotifier<DailyNutritionLog?> {
  @override
  Future<DailyNutritionLog?> build() {
    ref.watch(authControllerProvider);
    final date = ref.watch(journalDateProvider);

    return ref.read(nutritionApiClientProvider).fetchDailyNutritionLog(date);
  }

  Future<void> add({
    int deltaKcal = 0,
    double deltaProteinG = 0,
    double deltaCarbG = 0,
    double deltaFatG = 0,
  }) async {
    final date = ref.read(journalDateProvider);
    final log = await ref
        .read(nutritionApiClientProvider)
        .addDailyNutritionLog(
          date: date,
          deltaKcal: deltaKcal,
          deltaProteinG: deltaProteinG,
          deltaCarbG: deltaCarbG,
          deltaFatG: deltaFatG,
        );
    state = AsyncData(log);
  }
}
