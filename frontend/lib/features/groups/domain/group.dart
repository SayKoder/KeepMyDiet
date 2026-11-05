class Group {
  const Group({
    required this.id,
    required this.name,
    required this.createdAt,
    this.canEdit = false,
  });

  final int id;
  final String name;
  final DateTime createdAt;
  final bool canEdit;

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'] as int,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    canEdit: json['canEdit'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'canEdit': canEdit,
  };
}
