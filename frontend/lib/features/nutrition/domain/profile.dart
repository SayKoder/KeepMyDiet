import 'activity_level.dart';
import 'sex.dart';

/// `bmr`/`tdee`/`calorieGoal` sont calculés à la volée côté backend (jamais
/// stockés) — toujours à jour, même juste après un changement de poids.
class Profile {
  const Profile({
    required this.id,
    required this.sex,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.age,
    required this.bmr,
    required this.tdee,
    required this.calorieGoal,
    required this.calorieFloor,
    this.targetWeightKg,
    this.weeklyWeightLossGoalKg,
    this.estimatedWeeksToTarget,
  });

  final int id;
  final Sex sex;
  final DateTime birthDate;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final int age;
  final double bmr;
  final double tdee;
  final double calorieGoal;
  final double calorieFloor;
  final double? targetWeightKg;
  final double? weeklyWeightLossGoalKg;
  final int? estimatedWeeksToTarget;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as int,
        sex: Sex.fromJson(json['sex'] as String),
        birthDate: DateTime.parse(json['birthDate'] as String),
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        activityLevel: ActivityLevel.fromJson(json['activityLevel'] as String),
        age: json['age'] as int,
        bmr: (json['bmr'] as num).toDouble(),
        tdee: (json['tdee'] as num).toDouble(),
        calorieGoal: (json['calorieGoal'] as num).toDouble(),
        calorieFloor: (json['calorieFloor'] as num).toDouble(),
        targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
        weeklyWeightLossGoalKg: (json['weeklyWeightLossGoalKg'] as num?)?.toDouble(),
        estimatedWeeksToTarget: json['estimatedWeeksToTarget'] as int?,
      );
}
