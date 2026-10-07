import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/fridge_item.dart';
import '../domain/storage_location.dart';
import 'add_fridge_item_screen.dart';
import 'fridge_controller.dart';

class FridgeScreen extends ConsumerStatefulWidget {
  const FridgeScreen({super.key, required this.groupId, required this.groupName});

  final int groupId;
  final String groupName;

  @override
  ConsumerState<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends ConsumerState<FridgeScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(fridgeItemsProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Frigo'), Tab(text: 'Placard')],
        ),
      ),
      body: itemsAsync.when(
        data: (items) => TabBarView(
          controller: _tabController,
          children: [
            _ItemsList(
              items: items.where((i) => i.storageLocation == StorageLocation.fridge).toList(),
              groupId: widget.groupId,
            ),
            _ItemsList(
              items: items.where((i) => i.storageLocation == StorageLocation.pantry).toList(),
              groupId: widget.groupId,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddFridgeItemScreen(
              groupId: widget.groupId,
              defaultLocation:
                  _tabController.index == 0 ? StorageLocation.fridge : StorageLocation.pantry,
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
      return const Center(child: Text('Rien ici pour le moment.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(fridgeItemsProvider(groupId).future),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final expiryColor = item.isExpiringSoon ? Theme.of(context).colorScheme.error : null;

          return ListTile(
            title: Text(item.foodReference.name),
            subtitle: Text('${item.quantity.toStringAsFixed(0)} ${item.unit}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.expirationDate.day}/${item.expirationDate.month}/${item.expirationDate.year}',
                  style: TextStyle(color: expiryColor, fontWeight: item.isExpiringSoon ? FontWeight.bold : null),
                ),
                IconButton(
                  onPressed: () => deleteFridgeItem(ref, groupId: groupId, itemId: item.id),
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
