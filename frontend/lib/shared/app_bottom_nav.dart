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

  /// Hauteur réelle de la pilule (`Container` ci-dessous).
  static const double pillHeight = 72;

  /// Marge entre le bas de l'écran et le bas de la pilule : part de la vraie
  /// zone système de l'appareil (`MediaQuery.padding.bottom` — barre de
  /// gestes ou barre 3-boutons selon le téléphone, 0 sur certains, 30-48px
  /// sur d'autres) plutôt qu'un nombre fixe, jamais en dessous de 16 (valeur
  /// de la maquette). Une marge fixe de 24 ne suffisait pas sur les
  /// téléphones où cette barre est visible et plus haute — la pilule se
  /// retrouvait partiellement dessous, zone où les taps sont interceptés par
  /// le système plutôt que par l'app.
  static double bottomMargin(BuildContext context) {
    final systemBottomInset = MediaQuery.paddingOf(context).bottom;
    return systemBottomInset > 0 ? systemBottomInset + 12 : 16.0;
  }

  /// Hauteur totale occupée par la pilule (elle + sa marge) : la clearance à
  /// laisser à tout élément flottant qui lui est propre à l'écran (FAB...)
  /// pour passer AU-DESSUS d'elle plutôt que de se retrouver en partie
  /// dessous, visuellement masqué par elle ou par le dégradé qui la précède.
  static double floatingClearance(BuildContext context) =>
      bottomMargin(context) + pillHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // La pilule ne touche ni les bords ni le bas de l'écran — marge 16 de
      // chaque côté (valeur de la maquette), bas adapté à l'appareil ci-dessus.
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

/// FAB d'écran d'onglet (Recettes, Frigo...) qui flotte juste au-dessus de la
/// pilule — sans ce décalage, le `Scaffold` imbriqué de l'onglet positionne
/// déjà correctement le FAB tout seul, mais sa moitié basse reste prise dans
/// le léger dégradé anti-faux-clic de `HomeShell` (peint par-dessus dans le
/// `Stack` du shell), qui l'estompe comme s'il était passé dessous. Décalage
/// de la moitié de `floatingClearance` : exactement la hauteur de ce
/// dégradé (`fadeHeight` dans `home_shell.dart`), pour passer juste au-dessus.
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
