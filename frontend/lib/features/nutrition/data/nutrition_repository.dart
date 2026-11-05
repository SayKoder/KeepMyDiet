import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/nutrition/data/nutrition_api_client.dart';
import 'package:keepmydiet/features/nutrition/domain/activity_level.dart';
import 'package:keepmydiet/features/nutrition/domain/daily_nutrition_log.dart';
import 'package:keepmydiet/features/nutrition/domain/profile.dart';
import 'package:keepmydiet/features/nutrition/domain/sex.dart';
import 'package:keepmydiet/features/nutrition/domain/water_goal.dart';
import 'package:keepmydiet/features/nutrition/domain/water_intake.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(nutritionApiClientProvider));
});

class NutritionRepository {
  NutritionRepository(this._api);

  final NutritionApiClient _api;

  Future<Profile?> fetchMyProfile() => _api.fetchMyProfile();

  Future<Profile> createProfile({
    required Sex sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    double? targetWeightKg,
    double? weeklyWeightLossGoalKg,
  }) => _api.createProfile(
    sex: sex,
    birthDate: birthDate,
    heightCm: heightCm,
    weightKg: weightKg,
    activityLevel: activityLevel,
    targetWeightKg: targetWeightKg,
    weeklyWeightLossGoalKg: weeklyWeightLossGoalKg,
  );

  Future<Profile> updateProfile({
    required int id,
    required Sex sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    double? targetWeightKg,
    double? weeklyWeightLossGoalKg,
  }) => _api.updateProfile(
    id: id,
    sex: sex,
    birthDate: birthDate,
    heightCm: heightCm,
    weightKg: weightKg,
    activityLevel: activityLevel,
    targetWeightKg: targetWeightKg,
    weeklyWeightLossGoalKg: weeklyWeightLossGoalKg,
  );

  Future<DailyNutritionLog?> fetchDailyNutritionLog(DateTime date) =>
      _api.fetchDailyNutritionLog(date);

  Future<DailyNutritionLog> addDailyNutritionLog({
    required DateTime date,
    int deltaKcal = 0,
    double deltaProteinG = 0,
    double deltaCarbG = 0,
    double deltaFatG = 0,
  }) => _api.addDailyNutritionLog(
    date: date,
    deltaKcal: deltaKcal,
    deltaProteinG: deltaProteinG,
    deltaCarbG: deltaCarbG,
    deltaFatG: deltaFatG,
  );

  Future<WaterIntake?> fetchWaterIntakeForDate(DateTime date) =>
      _api.fetchWaterIntakeForDate(date);

  Future<WaterIntake> addWater(int deltaMl, {DateTime? date}) =>
      _api.addWater(deltaMl, date: date);

  Future<WaterGoal?> fetchMyWaterGoal() => _api.fetchMyWaterGoal();

  Future<WaterGoal> setWaterGoal(int goalMl) => _api.setWaterGoal(goalMl);

  Future<void> resetWaterGoal() => _api.resetWaterGoal();
}
