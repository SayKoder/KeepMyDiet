/// Le `token` est le seul champ qui compte côté UI : c'est ce qu'on partage
/// (copié/collé) à la personne qu'on invite pour qu'elle rejoigne le groupe.
class GroupInvitation {
  const GroupInvitation({required this.token});

  final String token;

  factory GroupInvitation.fromJson(Map<String, dynamic> json) =>
      GroupInvitation(token: json['token'] as String);
}
