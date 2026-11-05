import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../shared/home_navigation.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/async_value_ui.dart';
import '../../fridge/presentation/fridge_screen.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../groups/presentation/groups_list_screen.dart';
import '../../recipes/presentation/recipes_list_screen.dart';
import 'home_dashboard_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _destinations = [
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
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabIndexProvider);

    ref.listen(groupsControllerProvider, (_, next) {
      final groups = next.value;
      if (groups == null || groups.isEmpty) return;
      final current = ref.read(activeGroupProvider);
      if (current == null || !groups.any((g) => g.id == current.id)) {
        ref.read(activeGroupProvider.notifier).select(groups.first);
      }
    });

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
          const _BottomFade(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: index,
        onDestinationSelected: ref.read(homeTabIndexProvider.notifier).show,
        destinations: _destinations,
      ),
    );
  }
}

// Estompe le contenu qui passe sous la barre de navigation flottante.
class _BottomFade extends StatelessWidget {
  const _BottomFade();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: AppBottomNav.floatingClearance(context) / 2,
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
    );
  }
}

class _FridgeTab extends ConsumerWidget {
  const _FridgeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);
    final activeGroup = ref.watch(activeGroupProvider);

    return Scaffold(
      body: groupsAsync.toWidget(
        onRetry: () => ref.invalidate(groupsControllerProvider),
        isEmpty: (groups) => groups.isEmpty,
        empty: const EmptyState(
          icon: Icons.kitchen_outlined,
          title: 'Aucun groupe',
          message: "Crée un groupe ou rejoins-en un depuis l'onglet Groupes.",
        ),
        data: (groups) => FridgeScreen(group: _validGroup(groups, activeGroup)),
      ),
    );
  }

  Group _validGroup(List<Group> groups, Group? active) =>
      groups.firstWhere((g) => g.id == active?.id, orElse: () => groups.first);
}
