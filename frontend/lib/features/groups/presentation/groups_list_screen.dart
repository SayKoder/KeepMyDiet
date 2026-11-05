import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/auth/presentation/auth_controller.dart';
import 'package:keepmydiet/features/groups/domain/group.dart';
import 'package:keepmydiet/features/groups/presentation/create_group_screen.dart';
import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/features/groups/presentation/join_group_screen.dart';
import 'package:keepmydiet/features/groups/presentation/widgets/group_action_card.dart';
import 'package:keepmydiet/features/groups/presentation/widgets/group_card.dart';
import 'package:keepmydiet/features/groups/presentation/widgets/invite_card.dart';
import 'package:keepmydiet/shared/home_navigation.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  void _openFridge(WidgetRef ref, Group group) {
    ref.read(activeGroupProvider.notifier).select(group);
    ref.read(homeTabIndexProvider.notifier).show(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);
    final activeGroup = ref.watch(activeGroupProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: ref.read(groupsControllerProvider.notifier).refresh,
          child: groupsAsync.toWidget(
            onRetry: () => ref.invalidate(groupsControllerProvider),
            data: (groups) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Groupes',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  trailing: IconButton(
                    onPressed: ref.read(authControllerProvider.notifier).logout,
                    icon: const Icon(Icons.logout, size: 20),
                    tooltip: 'Se déconnecter',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: GroupActionCard(
                        label: 'Créer un groupe',
                        icon: Icons.add,
                        filled: true,
                        onTap: () => _open(context, const CreateGroupScreen()),
                      ),
                    ),
                    Expanded(
                      child: GroupActionCard(
                        label: 'Rejoindre avec un code',
                        icon: Icons.link,
                        onTap: () => _open(context, const JoinGroupScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'MES GROUPES',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 10),
                if (groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      "Tu n'as encore aucun groupe. Crée-en un ou rejoins-en "
                      "un via un code d'invitation.",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                for (final group in groups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GroupCard(
                      group: group,
                      isActive: group.id == activeGroup?.id,
                      onTap: () => _openFridge(ref, group),
                    ),
                  ),
                if (activeGroup != null) ...[
                  const SizedBox(height: 14),
                  InviteCard(group: activeGroup),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
