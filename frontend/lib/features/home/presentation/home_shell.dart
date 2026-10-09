import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../shared/app_bottom_nav.dart';
import '../../../shared/home_navigation.dart';
import '../../fridge/presentation/fridge_screen.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../groups/presentation/groups_list_screen.dart';
import '../../recipes/presentation/recipes_list_screen.dart';
import 'home_dashboard_screen.dart';

/// Héberge la bottom nav : 4 onglets, un seul `Scaffold` pour toute l'app.
/// `IndexedStack` (pas un `Navigator` par onglet) pour garder volontairement
/// chaque onglet simple — state Riverpod déjà mis en cache par provider, pas
/// besoin d'une pile de navigation par onglet pour ce qu'on affiche ici.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabIndexProvider);

    // Dès que la liste de groupes arrive (ou change), fixe automatiquement le
    // groupe actif sur le premier si aucun n'est choisi ou si celui choisi
    // n'existe plus (ex: on vient de le quitter) — évite un onglet Frigo vide
    // alors qu'un groupe existe déjà.
    ref.listen(groupsControllerProvider, (previous, next) {
      final groups = next.value;
      if (groups == null || groups.isEmpty) return;

      final current = ref.read(activeGroupProvider);
      if (current == null || !groups.any((g) => g.id == current.id)) {
        ref.read(activeGroupProvider.notifier).select(groups.first);
      }
    });

    // La pilule flotte au-dessus du contenu, donc en dessous d'elle le
    // contenu scrollable (dernier bouton d'une liste, etc.) reste visible et
    // peut sembler cliquable alors qu'il est en partie masqué par elle — on
    // l'estompe avec un dégradé non cliquable (`IgnorePointer`) juste avant
    // qu'il ne l'atteigne. Moitié de `floatingClearance` (pas sa totalité) :
    // un fondu sur toute cette hauteur débordait trop haut dans le contenu.
    final fadeHeight = AppBottomNav.floatingClearance(context) / 2;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: index,
            children: const [
              HomeDashboardScreen(),
              _FridgeTab(),
              RecipesListScreen(),
              GroupsListScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: fadeHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withValues(alpha: 0),
                      AppColors.background,
                    ],
                    stops: const [0, 0.65],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeTabIndexProvider.notifier).show(i),
        destinations: const [
          AppNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Accueil',
          ),
          AppNavDestination(
            icon: Icons.kitchen_outlined,
            selectedIcon: Icons.kitchen,
            label: 'Frigo',
          ),
          AppNavDestination(
            icon: Icons.restaurant_menu_outlined,
            selectedIcon: Icons.restaurant_menu,
            label: 'Recettes',
          ),
          AppNavDestination(
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups,
            label: 'Groupes',
          ),
        ],
      ),
    );
  }
}

class _FridgeTab extends ConsumerWidget {
  const _FridgeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);
    final activeGroup = ref.watch(activeGroupProvider);

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Frigo')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Tu n'as encore aucun groupe. Crée-en un ou rejoins-en un "
                  "depuis l'onglet Groupes.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          );
        }

        // Filet de sécurité en plus du `ref.listen` de HomeShell : garantit un
        // groupe valide affiché dès le premier build, même si le listener n'a
        // pas encore eu l'occasion de tourner.
        final group =
            activeGroup != null && groups.any((g) => g.id == activeGroup.id)
            ? activeGroup
            : groups.first;

        return FridgeScreen(group: group);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Erreur : $error'))),
    );
  }
}
