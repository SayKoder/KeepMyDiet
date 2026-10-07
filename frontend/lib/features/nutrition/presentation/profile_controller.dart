import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/nutrition_api_client.dart';
import '../domain/activity_level.dart';
import '../domain/profile.dart';
import '../domain/profile_failure.dart';
import '../domain/sex.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(ProfileController.new);

/// `null` = pas encore de profil créé (écran de création affiché à la place
/// du dashboard). Observe la session comme `GroupsController` : indispensable
/// ici aussi, sinon le profil de l'ancien compte resterait affiché après un
/// changement d'utilisateur.
class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() {
    ref.watch(authControllerProvider);

    return ref.read(nutritionApiClientProvider).fetchMyProfile();
  }

  Future<void> create({
    required Sex sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    double? targetWeightKg,
    double? weeklyWeightLossGoalKg,
  }) async {
    final Profile profile;
    try {
      profile = await ref.read(nutritionApiClientProvider).createProfile(
            sex: sex,
            birthDate: birthDate,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            targetWeightKg: targetWeightKg,
            weeklyWeightLossGoalKg: weeklyWeightLossGoalKg,
          );
    } on DioException catch (e) {
      throw ProfileFailure(extractErrorMessage(e));
    }

    state = AsyncData(profile);
  }

  /// Nommée `updateProfile`, pas `update` : `AsyncNotifier` définit déjà une
  /// méthode `update()` intégrée (aide à faire `state = await guard(...)`),
  /// s'appeler pareil aurait remplacé cette méthode au lieu d'en ajouter une.
  Future<void> updateProfile({
    required Sex sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    double? targetWeightKg,
    double? weeklyWeightLossGoalKg,
  }) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final Profile profile;
    try {
      profile = await ref.read(nutritionApiClientProvider).updateProfile(
            id: current.id,
            sex: sex,
            birthDate: birthDate,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            targetWeightKg: targetWeightKg,
            weeklyWeightLossGoalKg: weeklyWeightLossGoalKg,
          );
    } on DioException catch (e) {
      throw ProfileFailure(extractErrorMessage(e));
    }

    state = AsyncData(profile);
  }
}
