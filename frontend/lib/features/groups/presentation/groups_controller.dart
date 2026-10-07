import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/groups_api_client.dart';
import '../domain/group.dart';
import '../domain/group_failure.dart';
import '../domain/group_member.dart';

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

    return ref.read(groupsApiClientProvider).fetchMyGroups();
  }

  Future<Group> createGroup({required String name}) async {
    final Group group;
    try {
      group = await ref.read(groupsApiClientProvider).createGroup(name: name);
    } on DioException catch (e) {
      throw GroupFailure(extractErrorMessage(e));
    }

    state = AsyncData([...state.value ?? [], group]);

    return group;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(groupsApiClientProvider).fetchMyGroups());
  }
}

/// `.family` car il y a un membersProvider différent par groupe — Riverpod
/// crée/garde en cache une instance par `groupId` passé.
final groupMembersProvider = FutureProvider.family<List<GroupMember>, int>((ref, groupId) {
  return ref.watch(groupsApiClientProvider).fetchMembers(groupId);
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

final activeGroupProvider = NotifierProvider<ActiveGroupNotifier, Group?>(ActiveGroupNotifier.new);
