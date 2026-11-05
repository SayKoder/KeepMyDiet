import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/groups/data/groups_api_client.dart';
import 'package:keepmydiet/features/groups/domain/group.dart';
import 'package:keepmydiet/features/groups/domain/group_invitation.dart';
import 'package:keepmydiet/features/groups/domain/group_member.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(ref.watch(groupsApiClientProvider));
});

class GroupsRepository {
  GroupsRepository(this._api);

  final GroupsApiClient _api;

  Future<List<Group>> fetchMyGroups() => _api.fetchMyGroups();

  Future<Group> createGroup({required String name}) =>
      _api.createGroup(name: name);

  Future<List<GroupMember>> fetchMembers(int groupId) =>
      _api.fetchMembers(groupId);

  Future<GroupInvitation> createInvitation(int groupId) =>
      _api.createInvitation(groupId);

  Future<void> joinByToken(String token) => _api.joinByToken(token);
}
