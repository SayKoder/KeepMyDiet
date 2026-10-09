import 'package:flutter/material.dart';

import '../features/groups/domain/group.dart';

/// Bouton "changer de groupe" de l'AppBar (icône + menu déroulant des
/// groupes) — dupliqué à l'identique sur Frigo, Planning et le détail d'un
/// groupe. L'appelant garde la responsabilité de ne l'afficher que si
/// `groups.length > 1` (pas de sélecteur à n'avoir qu'un seul choix) : pas
/// géré ici pour que le widget reste un simple bouton, sans logique de
/// visibilité qui varie d'un écran à l'autre dans sa mise en page (`actions`
/// nullable sur certains écrans, liste conditionnelle sur d'autres).
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
