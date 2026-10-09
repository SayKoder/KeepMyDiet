class WaterIntake {
  const WaterIntake({
    required this.id,
    required this.date,
    required this.amountMl,
  });

  final int id;
  final DateTime date;
  final int amountMl;

  factory WaterIntake.fromJson(Map<String, dynamic> json) => WaterIntake(
    id: json['id'] as int,
    date: DateTime.parse(json['date'] as String),
    amountMl: json['amountMl'] as int,
  );
}
