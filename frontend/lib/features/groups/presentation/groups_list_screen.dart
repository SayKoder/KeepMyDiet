import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../shared/api_client.dart';
import '../../../shared/home_navigation.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/groups_api_client.dart';
import '../domain/group.dart';
import '../domain/group_member.dart';
import 'create_group_screen.dart';
import 'groups_controller.dart';
import 'join_group_screen.dart';

const _groupPalette = <(Color, Color)>[
  (AppColors.hero, AppColors.limeAccent),
  (Color(0xFFEAE7FD), Color(0xFF4B3BC4)),
  (Color(0xFFFEF1D3), Color(0xFF8A5A00)),
  (Color(0xFFDFF0FD), Color(0xFF135F99)),
];

const _memberAvatarPalette = <(Color, Color)>[
  (Color(0xFFFDE4EB), Color(0xFFB42450)),
  (Color(0xFFDFF0FD), Color(0xFF135F99)),
  (Color(0xFFFEF1D3), Color(0xFF8A5A00)),
];

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);
    final activeGroup = ref.watch(activeGroupProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(groupsControllerProvider.notifier).refresh(),
          child: groupsAsync.when(
            data: (groups) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Groupes', style: Theme.of(context).textTheme.headlineMedium),
                    IconButton(
                      onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                      icon: const Icon(Icons.logout, size: 20),
                      tooltip: 'Se déconnecter',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(44, 44),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Créer un groupe',
                        icon: Icons.add,
                        filled: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'Rejoindre avec un code',
                        icon: Icons.link,
                        filled: false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('MES GROUPES', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 10),
                if (groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      "Tu n'as encore aucun groupe. Crée-en un ou rejoins-en un via un code d'invitation.",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...groups.map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GroupCard(
                        group: group,
                        isActive: group.id == activeGroup?.id,
                        onTap: () {
                          ref.read(activeGroupProvider.notifier).select(group);
                          ref.read(homeTabIndexProvider.notifier).show(1);
                        },
                      ),
                    ),
                  ),
                if (activeGroup != null) ...[
                  const SizedBox(height: 14),
                  _InviteCard(group: activeGroup),
                ],
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erreur : $error')),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: filled ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: filled
                ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled ? Colors.white.withValues(alpha: 0.18) : AppColors.brandLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: filled ? Colors.white : AppColors.brandDark),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group, required this.isActive, required this.onTap});

  final Group group;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(group.id));
    final palette = _groupPalette[group.id % _groupPalette.length];
    final initial = group.name.isEmpty ? '?' : group.name[0].toUpperCase();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: EdgeInsets.all(isActive ? 14 : 15),
          decoration: BoxDecoration(
            border: Border.all(color: isActive ? AppColors.brand : AppColors.border, width: isActive ? 2 : 1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: palette.$1, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Text(initial, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: palette.$2)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    membersAsync.when(
                      data: (members) => isActive
                          ? _MemberAvatarStack(members: members)
                          : Text(
                              '${members.length} membre${members.length > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                      loading: () => const SizedBox(height: 24),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(999)),
                  child: const Text('Actif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandDark)),
                )
              else
                const Icon(Icons.chevron_right, size: 18, color: AppColors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberAvatarStack extends StatelessWidget {
  const _MemberAvatarStack({required this.members});

  final List<GroupMember> members;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(3).toList();

    return Row(
      children: [
        for (var i = 0; i < shown.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : -8),
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _memberAvatarPalette[i % _memberAvatarPalette.length].$1,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                shown[i].userEmail[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _memberAvatarPalette[i % _memberAvatarPalette.length].$2,
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          '${members.length} membre${members.length > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _InviteCard extends ConsumerStatefulWidget {
  const _InviteCard({required this.group});

  final Group group;

  @override
  ConsumerState<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends ConsumerState<_InviteCard> {
  String? _token;
  bool _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final invitation = await ref.read(groupsApiClientProvider).createInvitation(widget.group.id);
      if (mounted) {
        setState(() => _token = invitation.token);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Code d'invitation · ${widget.group.name}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  _token ?? 'Pas encore généré',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: _token != null ? 2 : 0,
                    color: _token != null ? AppColors.ink : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _isGenerating ? null : (_token == null ? _generate : () => Clipboard.setData(ClipboardData(text: _token!))),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            icon: Icon(_token == null ? Icons.vpn_key : Icons.copy, size: 16),
            label: Text(_token == null ? 'Générer' : 'Copier'),
          ),
        ],
      ),
    );
  }
}
