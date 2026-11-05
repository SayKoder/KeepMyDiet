import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/nutrition/data/nutrition_api_client.dart';
import 'package:keepmydiet/features/nutrition/domain/activity_level.dart';
import 'package:keepmydiet/features/nutrition/domain/daily_nutrition_log.dart';
import 'package:keepmydiet/features/nutrition/domain/profile.dart';
import 'package:keepmydiet/features/nutrition/domain/sex.dart';
import 'package:keepmydiet/features/nutrition/domain/water_goal.dart';
import 'package:keepmydiet/features/nutrition/domain/water_intake.dart';
import 'package:keepmydiet/shared/local_database.dart';
import 'package:keepmydiet/shared/network_first.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(
    ref.watch(nutritionApiClientProvider),
    ref.watch(localDatabaseProvider),
  );
});

class NutritionRepository {
  NutritionRepository(this._api, this._database);

  final NutritionApiClient _api;
  final LocalDatabase _database;

  Future<Profile?> fetchMyProfile() => networkFirst(
    _database,
    key: 'my_profile',
    fetch: _api.fetchMyProfile,
    toJson: (profile) => profile?.toJson(),
    fromJson: (json) =>
        json == null ? null : Profile.fromJson(json as Map<String, dynamic>),
  );

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
      networkFirst(
        _database,
        key: 'daily_log_${_day(date)}',
        fetch: () => _api.fetchDailyNutritionLog(date),
        toJson: (log) => log?.toJson(),
        fromJson: (json) => json == null
            ? null
            : DailyNutritionLog.fromJson(json as Map<String, dynamic>),
      );

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

  Future<WaterIntake?> fetchWaterIntakeForDate(DateTime date) => networkFirst(
    _database,
    key: 'water_intake_${_day(date)}',
    fetch: () => _api.fetchWaterIntakeForDate(date),
    toJson: (intake) => intake?.toJson(),
    fromJson: (json) => json == null
        ? null
        : WaterIntake.fromJson(json as Map<String, dynamic>),
  );

  Future<WaterIntake> addWater(int deltaMl, {DateTime? date}) =>
      _api.addWater(deltaMl, date: date);

  Future<WaterGoal?> fetchMyWaterGoal() => networkFirst(
    _database,
    key: 'water_goal',
    fetch: _api.fetchMyWaterGoal,
    toJson: (goal) => goal?.toJson(),
    fromJson: (json) =>
        json == null ? null : WaterGoal.fromJson(json as Map<String, dynamic>),
  );

  Future<WaterGoal> setWaterGoal(int goalMl) => _api.setWaterGoal(goalMl);

  Future<void> resetWaterGoal() => _api.resetWaterGoal();

  String _day(DateTime date) => date.toIso8601String().substring(0, 10);
}
