import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/fridge/domain/fridge_failure.dart';
import 'package:keepmydiet/features/fridge/domain/fridge_item.dart';
import 'package:keepmydiet/features/fridge/domain/storage_location.dart';
import 'package:keepmydiet/features/fridge/presentation/add_fridge_item_screen.dart';
import 'package:keepmydiet/features/fridge/presentation/fridge_controller.dart';
import 'package:keepmydiet/features/fridge/presentation/widgets/expiring_banner.dart';
import 'package:keepmydiet/features/fridge/presentation/widgets/fridge_header.dart';
import 'package:keepmydiet/features/fridge/presentation/widgets/fridge_item_card.dart';
import 'package:keepmydiet/features/groups/domain/group.dart';
import 'package:keepmydiet/features/groups/presentation/group_events_controller.dart';
import 'package:keepmydiet/features/recipe_suggestions/presentation/recipe_suggestions_screen.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class FridgeScreen extends ConsumerStatefulWidget {
  const FridgeScreen({super.key, required this.group});

  final Group group;

  @override
  ConsumerState<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends ConsumerState<FridgeScreen> {
  StorageLocation _selected = StorageLocation.fridge;

  @override
  Widget build(BuildContext context) {
    final groupId = widget.group.id;
    final itemsAsync = ref.watch(fridgeItemsProvider(groupId));
    final allItems = itemsAsync.value ?? [];
    ref.onGroupEvent(
      groupId,
      'fridge',
      () => ref.invalidate(fridgeItemsProvider(groupId)),
    );

    return LiveRefresh(
      interval: liveRefreshInterval,
      onRefresh: () => ref.invalidate(fridgeItemsProvider(groupId)),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    FridgeHeader(group: widget.group),
                    const SizedBox(height: 20),
                    SegmentedPill<StorageLocation>(
                      values: StorageLocation.values,
                      selected: _selected,
                      labelOf: (location) => location.label,
                      badgeOf: (location) => allItems
                          .where((i) => i.storageLocation == location)
                          .length
                          .toString(),
                      onChanged: (location) =>
                          setState(() => _selected = location),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: itemsAsync.toWidget(
                  onRetry: () => ref.invalidate(fridgeItemsProvider(groupId)),
                  data: (items) => _ItemsList(
                    items: items
                        .where((i) => i.storageLocation == _selected)
                        .toList(),
                    group: widget.group,
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FabAboveNav(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddFridgeItemScreen(
                groupId: groupId,
                defaultLocation: _selected,
              ),
            ),
          ),
          tooltip: 'Ajouter un aliment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ItemsList extends ConsumerWidget {
  const _ItemsList({required this.items, required this.group});

  final List<FridgeItem> items;
  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.kitchen_outlined,
        title: 'Rien ici pour le moment',
        message: 'Ajoute un aliment avec le bouton +.',
      );
    }

    final sorted = [...items]
      ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    final expiringCount = sorted.where((i) => i.isExpiringSoon).length;

    final rows = [
      if (expiringCount > 0)
        ExpiringBanner(
          count: expiringCount,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecipeSuggestionsScreen(
                groupId: group.id,
                groupName: group.name,
              ),
            ),
          ),
        ),
      for (final item in sorted)
        Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          confirmDismiss: (_) => _delete(context, ref, item),
          child: FridgeItemCard(item: item),
        ),
      const Text(
        'Glisser une ligne vers la gauche pour la supprimer',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.refresh(fridgeItemsProvider(group.id).future),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
        itemCount: rows.length,
        itemBuilder: (_, index) => rows[index],
        separatorBuilder: (_, _) => const SizedBox(height: 10),
      ),
    );
  }

  Future<bool> _delete(
    BuildContext context,
    WidgetRef ref,
    FridgeItem item,
  ) async {
    try {
      await deleteFridgeItem(ref, groupId: group.id, itemId: item.id);
      return true;
    } on FridgeFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return false;
    }
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Icon(Icons.delete_outline, color: AppColors.errorText),
    );
  }
}
