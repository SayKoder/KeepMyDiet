import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../nutrition/presentation/nutrition_dashboard_screen.dart';
import '../../recipes/presentation/recipes_list_screen.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'groups_controller.dart';
import 'join_group_screen.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes groupes'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NutritionDashboardScreen()),
            ),
            icon: const Icon(Icons.monitor_heart_outlined),
            tooltip: 'Nutrition',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecipesListScreen()),
            ),
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Recettes',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
            ),
            icon: const Icon(Icons.group_add),
            tooltip: 'Rejoindre un groupe',
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(groupsControllerProvider.notifier).refresh(),
        child: groupsAsync.when(
          data: (groups) => groups.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        "Tu n'as encore aucun groupe. Crée-en un ou rejoins-en un via un code d'invitation.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return ListTile(
                      leading: const Icon(Icons.groups),
                      title: Text(group.name),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur : $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
        ),
        tooltip: 'Créer un groupe',
        child: const Icon(Icons.add),
      ),
    );
  }
}
