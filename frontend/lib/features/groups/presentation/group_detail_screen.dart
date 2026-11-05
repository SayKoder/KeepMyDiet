import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../../../shared/widgets/async_value_ui.dart';
import '../../../shared/widgets/group_switcher_menu_button.dart';
import '../data/groups_api_client.dart';
import '../domain/group.dart';
import 'groups_controller.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.group});

  final Group group;

  // Seuls les admins peuvent inviter : le backend renvoie 403 sinon.
  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    try {
      final invitation = await ref
          .read(groupsApiClientProvider)
          .createInvitation(group.id);
      if (context.mounted) await _showCode(context, invitation.token);
    } on DioException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _showCode(BuildContext context, String token) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Code à partager'),
        content: SelectableText(token),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Copier et fermer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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
              onSelected: ref.read(activeGroupProvider.notifier).select,
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
          data: (members) => ListView(
            children: [
              for (final member in members)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(member.userEmail),
                  trailing: Chip(label: Text(member.role.label)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
