import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/auth/presentation/auth_controller.dart';
import 'package:keepmydiet/features/groups/data/groups_repository.dart';
import 'package:keepmydiet/features/groups/domain/group.dart';
import 'package:keepmydiet/features/groups/domain/group_failure.dart';
import 'package:keepmydiet/features/groups/domain/group_member.dart';
import 'package:keepmydiet/shared/api_client.dart';

final groupsControllerProvider =
    AsyncNotifierProvider<GroupsController, List<Group>>(GroupsController.new);

/// Liste des groupes de l'utilisateur courant (`MyGroupsProvider` côté
/// backend — jamais de liste globale, uniquement les groupes dont on est
/// membre).
class GroupsController extends AsyncNotifier<List<Group>> {
  @override
  Future<List<Group>> build() {
    // `watch` (pas `read`) : sans ça, se déconnecter puis se reconnecter avec
    // un AUTRE compte réaffiche les groupes du compte précédent — Riverpod
    // garde ce provider en cache tant que rien ne lui dit de se reconstruire.
    // En observant la session, un changement (login/logout) invalide
    // automatiquement ce cache et relance `fetchMyGroups()` à jour.
    ref.watch(authControllerProvider);

    return ref.read(groupsRepositoryProvider).fetchMyGroups();
  }

  Future<Group> createGroup({required String name}) async {
    final Group group;
    try {
      group = await ref.read(groupsRepositoryProvider).createGroup(name: name);
    } on DioException catch (e) {
      throw GroupFailure(extractErrorMessage(e));
    }

    state = AsyncData([...state.value ?? [], group]);

    return group;
  }

  Future<void> renameGroup(Group group, String name) async {
    final Group updated;
    try {
      updated = await ref
          .read(groupsRepositoryProvider)
          .updateGroup(group.id, name: name);
    } on DioException catch (e) {
      throw GroupFailure(extractErrorMessage(e));
    }

    state = AsyncData([
      for (final g in state.value ?? <Group>[])
        g.id == updated.id ? updated : g,
    ]);
    if (ref.read(activeGroupProvider)?.id == updated.id) {
      ref.read(activeGroupProvider.notifier).select(updated);
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(groupsRepositoryProvider).fetchMyGroups(),
    );
  }
}

/// `.family` car il y a un membersProvider différent par groupe — Riverpod
/// crée/garde en cache une instance par `groupId` passé.
final groupMembersProvider = FutureProvider.family<List<GroupMember>, int>((
  ref,
  groupId,
) {
  return ref.watch(groupsRepositoryProvider).fetchMembers(groupId);
});

/// Groupe affiché dans l'onglet Frigo. Null tant qu'aucun groupe n'a encore
/// été résolu (`HomeShell` le fixe automatiquement sur le premier groupe dès
/// que la liste arrive) ; changé manuellement via le sélecteur de
/// `GroupDetailScreen` si l'utilisateur a plusieurs groupes.
class ActiveGroupNotifier extends Notifier<Group?> {
  @override
  Group? build() => null;

  void select(Group group) => state = group;
}

final activeGroupProvider = NotifierProvider<ActiveGroupNotifier, Group?>(
  ActiveGroupNotifier.new,
);
