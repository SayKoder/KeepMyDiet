import 'package:flutter/material.dart';

import 'package:keepmydiet/features/groups/domain/group.dart';

class GroupSwitcherMenuButton extends StatelessWidget {
  const GroupSwitcherMenuButton({
    super.key,
    required this.groups,
    required this.onSelected,
  });

  final List<Group> groups;
  final ValueChanged<Group> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Group>(
      icon: const Icon(Icons.swap_horiz),
      tooltip: 'Changer de groupe',
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final g in groups) PopupMenuItem(value: g, child: Text(g.name)),
      ],
    );
  }
}
