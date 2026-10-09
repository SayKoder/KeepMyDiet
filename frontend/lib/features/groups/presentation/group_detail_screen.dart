import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../../../shared/async_value_ui.dart';
import '../../../shared/group_switcher_menu_button.dart';
import '../data/groups_api_client.dart';
import '../domain/group.dart';
import 'groups_controller.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.group});

  final Group group;

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    try {
      final invitation = await ref
          .read(groupsApiClientProvider)
          .createInvitation(group.id);
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Code à partager'),
            content: SelectableText(invitation.token),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: invitation.token));
                  Navigator.of(context).pop();
                },
                child: const Text('Copier et fermer'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } on DioException catch (e) {
      // Seuls les admins du groupe peuvent inviter (403 sinon) — voir
      // CreateInvitationProcessor côté backend. Pas encore de moyen simple
      // de savoir côté client si on est admin avant de tenter, donc on
      // laisse le backend trancher et on affiche l'erreur telle quelle.
      if (context.mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(group.id));
    final groups = ref.watch(groupsControllerProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          if (groups.length > 1)
            GroupSwitcherMenuButton(
              groups: groups,
              onSelected: (selected) =>
                  ref.read(activeGroupProvider.notifier).select(selected),
            ),
          IconButton(
            onPressed: () => _invite(context, ref),
            icon: const Icon(Icons.person_add),
            tooltip: 'Inviter',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(groupMembersProvider(group.id).future),
        child: membersAsync.toWidget(
          onRetry: () => ref.invalidate(groupMembersProvider(group.id)),
          data: (members) => ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(member.userEmail),
                trailing: Chip(label: Text(member.role.label)),
              );
            },
          ),
        ),
      ),
    );
  }
}
