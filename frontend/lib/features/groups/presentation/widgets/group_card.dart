import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/groups/domain/group.dart';
import 'package:keepmydiet/features/groups/domain/group_member.dart';
import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class GroupCard extends ConsumerWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.isActive,
    required this.onTap,
  });

  final Group group;
  final bool isActive;
  final VoidCallback onTap;

  static const _palette = [
    (AppColors.hero, AppColors.limeAccent),
    (Color(0xFFEAE7FD), Color(0xFF4B3BC4)),
    (Color(0xFFFEF1D3), Color(0xFF8A5A00)),
    (Color(0xFFDFF0FD), Color(0xFF135F99)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(groupMembersProvider(group.id)).value;
    final (background, foreground) = _palette[group.id % _palette.length];

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(14),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: isActive ? AppColors.brand : AppColors.border,
          width: isActive ? 2 : 1,
        ),
      ),
      leading: LetterAvatar(
        text: group.name,
        background: background,
        foreground: foreground,
        size: 52,
        radius: AppRadius.md,
      ),
      title: Text(
        group.name,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      subtitle: members == null ? null : _MembersSummary(members: members),
      trailing: isActive
          ? const Pill(
              label: 'Actif',
              background: AppColors.brandLight,
              foreground: AppColors.brandDark,
            )
          : const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.iconMuted,
            ),
    );
  }
}

class _MembersSummary extends StatelessWidget {
  const _MembersSummary({required this.members});

  final List<GroupMember> members;

  static const _palette = [
    (Color(0xFFFDE4EB), Color(0xFFB42450)),
    (Color(0xFFDFF0FD), Color(0xFF135F99)),
    (Color(0xFFFEF1D3), Color(0xFF8A5A00)),
  ];

  @override
  Widget build(BuildContext context) {
    final shown = members.take(3).toList();
    final count = members.length;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          for (final (index, member) in shown.indexed)
            Align(
              widthFactor: 0.7,
              child: LetterAvatar(
                text: member.userEmail,
                background: _palette[index % _palette.length].$1,
                foreground: _palette[index % _palette.length].$2,
                size: 24,
                circle: true,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            '$count membre${count > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
