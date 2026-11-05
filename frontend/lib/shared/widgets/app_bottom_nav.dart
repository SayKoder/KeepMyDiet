import 'package:flutter/material.dart';

import 'package:keepmydiet/core/theme.dart';

class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

// Pilule flottante de la maquette (le NavigationBar Material n'en propose pas).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavDestination> destinations;

  static const double pillHeight = 72;

  // Tient compte de la barre système du téléphone (gestes ou 3 boutons).
  static double bottomMargin(BuildContext context) {
    final systemBottomInset = MediaQuery.paddingOf(context).bottom;
    return systemBottomInset > 0 ? systemBottomInset + 12 : 16.0;
  }

  // Hauteur à laisser libre pour qu'un élément flottant passe au-dessus.
  static double floatingClearance(BuildContext context) =>
      bottomMargin(context) + pillHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin(context)),
      child: Container(
        height: pillHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.14),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                flex: i == selectedIndex ? 3 : 2,
                child: _NavItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// FAB remonté au-dessus du dégradé qui précède la barre de navigation.
class FabAboveNav extends StatelessWidget {
  const FabAboveNav({
    super.key,
    required this.onPressed,
    required this.tooltip,
    required this.child,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppBottomNav.floatingClearance(context) / 2,
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        child: child,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: selected ? AppColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: selected ? 20 : 22,
                  color: selected ? Colors.white : AppColors.iconMuted,
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Text(
                    destination.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
