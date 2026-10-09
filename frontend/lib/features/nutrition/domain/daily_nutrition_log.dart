class DailyNutritionLog {
  const DailyNutritionLog({
    required this.id,
    required this.date,
    required this.caloriesConsumed,
    required this.proteinConsumedG,
    required this.carbConsumedG,
    required this.fatConsumedG,
  });

  final int id;
  final DateTime date;
  final int caloriesConsumed;
  final double proteinConsumedG;
  final double carbConsumedG;
  final double fatConsumedG;

  factory DailyNutritionLog.fromJson(Map<String, dynamic> json) => DailyNutritionLog(
        id: json['id'] as int,
        date: DateTime.parse(json['date'] as String),
        caloriesConsumed: json['caloriesConsumed'] as int,
        proteinConsumedG: (json['proteinConsumedG'] as num).toDouble(),
        carbConsumedG: (json['carbConsumedG'] as num).toDouble(),
        fatConsumedG: (json['fatConsumedG'] as num).toDouble(),
      );
}
