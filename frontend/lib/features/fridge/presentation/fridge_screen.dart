import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/async_value_ui.dart';
import '../../../shared/group_switcher_menu_button.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/group_detail_screen.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../recipe_suggestions/presentation/recipe_suggestions_screen.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';
import '../domain/fridge_item.dart';
import '../domain/storage_location.dart';
import 'add_fridge_item_screen.dart';
import 'fridge_controller.dart';

/// Contenu de l'onglet Frigo (`HomeShell`) : atterrit directement sur le
/// frigo/placard du groupe actif, avec les actions liées au groupe (courses,
/// suggestions, infos/invitation) en accès direct dans l'AppBar — pas besoin
/// de passer par un écran intermédiaire pour y arriver.
class FridgeScreen extends ConsumerStatefulWidget {
  const FridgeScreen({super.key, required this.group});

  final Group group;

  @override
  ConsumerState<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends ConsumerState<FridgeScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.group.id;
    final itemsAsync = ref.watch(fridgeItemsProvider(groupId));
    final groups = ref.watch(groupsControllerProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          if (groups.length > 1)
            GroupSwitcherMenuButton(
              groups: groups,
              onSelected: (selected) =>
                  ref.read(activeGroupProvider.notifier).select(selected),
            ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShoppingListScreen(
                  groupId: groupId,
                  groupName: widget.group.name,
                ),
              ),
            ),
            icon: const Icon(Icons.checklist),
            tooltip: 'Liste de courses',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeSuggestionsScreen(
                  groupId: groupId,
                  groupName: widget.group.name,
                ),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Suggestions de recettes',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(group: widget.group),
              ),
            ),
            icon: const Icon(Icons.group_outlined),
            tooltip: 'Membres et invitation',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Frigo'),
            Tab(text: 'Placard'),
          ],
        ),
      ),
      body: itemsAsync.toWidget(
        onRetry: () => ref.invalidate(fridgeItemsProvider(groupId)),
        data: (items) => TabBarView(
          controller: _tabController,
          children: [
            _ItemsList(
              items: items
                  .where((i) => i.storageLocation == StorageLocation.fridge)
                  .toList(),
              groupId: groupId,
            ),
            _ItemsList(
              items: items
                  .where((i) => i.storageLocation == StorageLocation.pantry)
                  .toList(),
              groupId: groupId,
            ),
          ],
        ),
      ),
      floatingActionButton: FabAboveNav(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddFridgeItemScreen(
              groupId: groupId,
              defaultLocation: _tabController.index == 0
                  ? StorageLocation.fridge
                  : StorageLocation.pantry,
            ),
          ),
        ),
        tooltip: 'Ajouter un aliment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ItemsList extends ConsumerWidget {
  const _ItemsList({required this.items, required this.groupId});

  final List<FridgeItem> items;
  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.kitchen_outlined,
        title: 'Rien ici pour le moment',
        message: 'Ajoute un aliment avec le bouton +.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(fridgeItemsProvider(groupId).future),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final expiryColor = item.isExpiringSoon
              ? Theme.of(context).colorScheme.error
              : null;

          return ListTile(
            title: Text(item.foodReference.name),
            subtitle: Text('${item.quantity.toStringAsFixed(0)} ${item.unit}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.expirationDate.day}/${item.expirationDate.month}/${item.expirationDate.year}',
                  style: TextStyle(
                    color: expiryColor,
                    fontWeight: item.isExpiringSoon ? FontWeight.bold : null,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      deleteFridgeItem(ref, groupId: groupId, itemId: item.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
