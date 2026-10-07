class WaterGoal {
  const WaterGoal({required this.goalMl});

  final int goalMl;

  factory WaterGoal.fromJson(Map<String, dynamic> json) => WaterGoal(goalMl: json['goalMl'] as int);
}
