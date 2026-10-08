import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Un onglet de `AppBottomNav` : une icône (+ sa variante "actif") et un
/// libellé affiché seulement sur l'onglet sélectionné.
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

/// Barre de navigation flottante de la maquette : une pilule blanche avec
/// ombre, l'onglet actif devient une pilule sombre (icône + libellé), les
/// autres restent juste une icône grise. Pas le `NavigationBar` de Material
/// (qui est un simple bandeau plein, sans pilule flottante ni largeur
/// variable par onglet) — on construit ce widget à la main.
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      // La pilule ne touche ni les bords ni le bas de l'écran — marge 16 de
      // chaque côté, 24 en bas (valeurs de la maquette).
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        height: 72,
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
                // L'onglet actif occupe plus de largeur (icône + libellé) que
                // les autres (icône seule) — ratio 3:2, repris de la maquette
                // (colonnes de grille 1.5fr / 1fr).
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
        // `InkWell` a besoin d'un ancêtre `Material` pour dessiner l'effet
        // d'encre du tap (le "splash") — sans lui, `onTap` marcherait quand
        // même mais sans aucun retour visuel.
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
