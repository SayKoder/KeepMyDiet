import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../domain/activity_level.dart';
import '../domain/profile.dart';
import '../domain/sex.dart';

final nutritionApiClientProvider = Provider<NutritionApiClient>((ref) {
  return NutritionApiClient(ref.watch(dioProvider));
});

class NutritionApiClient {
  NutritionApiClient(this._dio);

  final Dio _dio;
  static final _ldJson = Options(contentType: 'application/ld+json');

  /// `/profiles` n'est pas une vraie collection : 0 ou 1 élément, le profil
  /// de l'utilisateur courant (voir MyProfileProvider côté backend) — c'est
  /// le seul moyen pour le client de connaître l'id de SON profil.
  Future<Profile?> fetchMyProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/profiles');
    final members = response.data!['member'] as List<dynamic>;

    return members.isEmpty ? null : Profile.fromJson(members.first as Map<String, dynamic>);
  }

  Future<Profile> createProfile({
    required Sex sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    double? targetWeightKg,
    double? weeklyWeightLossGoalKg,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/profiles',
      data: _toJson(sex, birthDate, heightCm, weightKg, activityLevel, targetWeightKg, weeklyWeightLossGoalKg),
      options: _ldJson,
    );

    return Profile.fromJson(response.data!);
  }

  Future<Profile> updateProfile({
    required int id,
    required Sex sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    double? targetWeightKg,
    double? weeklyWeightLossGoalKg,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/profiles/$id',
      data: _toJson(sex, birthDate, heightCm, weightKg, activityLevel, targetWeightKg, weeklyWeightLossGoalKg),
      options: Options(contentType: 'application/merge-patch+json'),
    );

    return Profile.fromJson(response.data!);
  }

  Map<String, dynamic> _toJson(
    Sex sex,
    DateTime birthDate,
    double heightCm,
    double weightKg,
    ActivityLevel activityLevel,
    double? targetWeightKg,
    double? weeklyWeightLossGoalKg,
  ) {
    final iso = birthDate.toIso8601String().split('T').first;

    return {
      'sex': sex.name,
      'birthDate': iso,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel.toJson(),
      // merge-patch+json : null efface explicitement la valeur côté backend
      // (désactiver le rythme personnalisé doit repasser au déficit fixe de
      // 20%), donc pas de syntaxe `?value` ici — on veut la clé même à null.
      'targetWeightKg': targetWeightKg,
      'weeklyWeightLossGoalKg': weeklyWeightLossGoalKg,
    };
  }
}
