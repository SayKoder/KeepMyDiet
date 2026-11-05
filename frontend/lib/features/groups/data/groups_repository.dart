import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/groups/data/groups_api_client.dart';
import 'package:keepmydiet/features/groups/domain/group.dart';
import 'package:keepmydiet/features/groups/domain/group_invitation.dart';
import 'package:keepmydiet/features/groups/domain/group_member.dart';
import 'package:keepmydiet/shared/local_database.dart';
import 'package:keepmydiet/shared/network_first.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(
    ref.watch(groupsApiClientProvider),
    ref.watch(localDatabaseProvider),
  );
});

class GroupsRepository {
  GroupsRepository(this._api, this._database);

  final GroupsApiClient _api;
  final LocalDatabase _database;

  Future<List<Group>> fetchMyGroups() => networkFirst(
    _database,
    key: 'my_groups',
    fetch: _api.fetchMyGroups,
    toJson: (groups) => [for (final group in groups) group.toJson()],
    fromJson: (json) => [
      for (final group in json as List)
        Group.fromJson(group as Map<String, dynamic>),
    ],
  );

  Future<Group> createGroup({required String name}) =>
      _api.createGroup(name: name);

  Future<Group> updateGroup(int groupId, {required String name}) =>
      _api.updateGroup(groupId, name: name);

  Future<List<GroupMember>> fetchMembers(int groupId) => networkFirst(
    _database,
    key: 'group_members_$groupId',
    fetch: () => _api.fetchMembers(groupId),
    toJson: (members) => [for (final member in members) member.toJson()],
    fromJson: (json) => [
      for (final member in json as List)
        GroupMember.fromJson(member as Map<String, dynamic>),
    ],
  );

  Future<GroupInvitation> createInvitation(int groupId) =>
      _api.createInvitation(groupId);

  Future<void> joinByToken(String token) => _api.joinByToken(token);
}
