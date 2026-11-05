import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/groups/domain/group.dart';
import 'package:keepmydiet/features/groups/presentation/group_detail_screen.dart';
import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/features/recipe_suggestions/presentation/recipe_suggestions_screen.dart';
import 'package:keepmydiet/features/shopping_list/presentation/shopping_list_screen.dart';

class FridgeHeader extends ConsumerWidget {
  const FridgeHeader({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsControllerProvider).value ?? [];

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Groupe',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              _GroupName(
                group: group,
                groups: groups,
                onSelected: (selected) =>
                    ref.read(activeGroupProvider.notifier).select(selected),
              ),
            ],
          ),
        ),
        _RoundIconButton(
          icon: Icons.shopping_cart_outlined,
          tooltip: 'Liste de courses',
          page: ShoppingListScreen(groupId: group.id, groupName: group.name),
        ),
        _RoundIconButton(
          icon: Icons.auto_awesome_outlined,
          tooltip: 'Suggestions de recettes',
          page: RecipeSuggestionsScreen(
            groupId: group.id,
            groupName: group.name,
          ),
        ),
        _RoundIconButton(
          icon: Icons.person_add_alt_outlined,
          tooltip: 'Membres et invitation',
          page: GroupDetailScreen(group: group),
        ),
      ],
    );
  }
}

class _GroupName extends StatelessWidget {
  const _GroupName({
    required this.group,
    required this.groups,
    required this.onSelected,
  });

  final Group group;
  final List<Group> groups;
  final ValueChanged<Group> onSelected;

  @override
  Widget build(BuildContext context) {
    final name = Text(
      group.name,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineMedium,
    );

    if (groups.length < 2) {
      return name;
    }

    return PopupMenuButton<Group>(
      tooltip: 'Changer de groupe',
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final g in groups) PopupMenuItem(value: g, child: Text(g.name)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: name),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.page,
  });

  final IconData icon;
  final String tooltip;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconButton(
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
        tooltip: tooltip,
        icon: Icon(icon, color: AppColors.ink, size: 22),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          minimumSize: const Size(46, 46),
          shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        ),
      ),
    );
  }
}
