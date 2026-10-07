import 'group_role.dart';

/// Une adhésion (`GroupMembership` côté backend). `user` est embarqué
/// directement dans le JSON grâce à `#[ApiProperty(readableLink: true)]` sur
/// l'entité — sans ça on n'aurait qu'une IRI ("/api/users/5") et il faudrait
/// une requête en plus pour afficher l'email.
class GroupMember {
  const GroupMember({
    required this.id,
    required this.userEmail,
    required this.role,
    required this.joinedAt,
  });

  final int id;
  final String userEmail;
  final GroupRole role;
  final DateTime joinedAt;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;

    return GroupMember(
      id: json['id'] as int,
      userEmail: user['email'] as String,
      role: GroupRole.fromJson(json['role'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}
