import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/fridge/domain/storage_location.dart';

/// `foodReference` est embarqué directement dans le JSON (readableLink côté
/// backend) — pas besoin d'une requête séparée pour afficher le nom/macros.
class FridgeItem {
  const FridgeItem({
    required this.id,
    required this.foodReference,
    required this.storageLocation,
    required this.quantity,
    required this.unit,
    required this.expirationDate,
  });

  final int id;
  final FoodReference foodReference;
  final StorageLocation storageLocation;
  final double quantity;
  final String unit;
  final DateTime expirationDate;

  factory FridgeItem.fromJson(Map<String, dynamic> json) => FridgeItem(
    id: json['id'] as int,
    foodReference: FoodReference.fromJson(
      json['foodReference'] as Map<String, dynamic>,
    ),
    storageLocation: StorageLocation.fromJson(
      json['storageLocation'] as String,
    ),
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] as String,
    expirationDate: DateTime.parse(json['expirationDate'] as String),
  );

  /// Urgence visuelle (anti-gaspillage) : DLC dans moins de 3 jours.
  bool get isExpiringSoon =>
      expirationDate.difference(DateTime.now()).inDays < 3;

  Map<String, dynamic> toJson() => {
    'id': id,
    'foodReference': foodReference.toJson(),
    'storageLocation': storageLocation.name,
    'quantity': quantity,
    'unit': unit,
    'expirationDate': expirationDate.toIso8601String(),
  };
}
