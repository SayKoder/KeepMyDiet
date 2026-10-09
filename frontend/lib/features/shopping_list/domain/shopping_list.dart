import 'shopping_list_item.dart';

/// Une seule liste "active" par groupe côté backend — voir ShoppingListApiClient.
class ShoppingList {
  const ShoppingList({required this.id, required this.items});

  final int id;
  final List<ShoppingListItem> items;

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
    id: json['id'] as int,
    items: (json['items'] as List<dynamic>)
        .map((e) => ShoppingListItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
