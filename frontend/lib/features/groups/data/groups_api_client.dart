import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../domain/group.dart';
import '../domain/group_invitation.dart';
import '../domain/group_member.dart';

final groupsApiClientProvider = Provider<GroupsApiClient>((ref) {
  return GroupsApiClient(ref.watch(dioProvider));
});

/// Le skeleton API Platform du backend n'a que le format JSON-LD d'activé
/// (pas le JSON "plat") — d'où le `application/ld+json` systématique en
/// écriture, et le `member` (pas un simple tableau) à extraire en lecture de
/// collection : `{"@context": ..., "member": [...], "totalItems": ...}`.
class GroupsApiClient {
  GroupsApiClient(this._dio);

  final Dio _dio;
  static final _ldJson = Options(contentType: 'application/ld+json');

  Future<List<Group>> fetchMyGroups() async {
    final response = await _dio.get<Map<String, dynamic>>('/groups');
    final members = response.data!['member'] as List<dynamic>;

    return members.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Group> createGroup({required String name}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups',
      data: {'name': name},
      options: _ldJson,
    );

    return Group.fromJson(response.data!);
  }

  Future<List<GroupMember>> fetchMembers(int groupId) async {
    final response = await _dio.get<Map<String, dynamic>>('/groups/$groupId/memberships');
    final members = response.data!['member'] as List<dynamic>;

    return members.map((e) => GroupMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Réservé aux admins du groupe — le backend renvoie un 403 sinon (voir
  /// `CreateInvitationProcessor`), qu'on remonte comme une erreur classique.
  Future<GroupInvitation> createInvitation(int groupId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/group_invitations',
      data: {'group': '/api/groups/$groupId'},
      options: _ldJson,
    );

    return GroupInvitation.fromJson(response.data!);
  }

  /// Toujours autorisé, même si déjà membre d'autres groupes — l'API renvoie
  /// juste un 409 si on est déjà membre de CE groupe précis.
  Future<void> joinByToken(String token) async {
    await _dio.post<Map<String, dynamic>>(
      '/group_invitations/join',
      data: {'token': token},
      options: _ldJson,
    );
  }
}
