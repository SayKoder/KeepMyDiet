import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:keepmydiet/features/fridge/domain/storage_location.dart';
import 'package:keepmydiet/features/shopping_list/data/shopping_list_api_client.dart';
import 'package:keepmydiet/features/shopping_list/domain/shopping_list_item.dart';
import 'package:keepmydiet/features/shopping_list/presentation/shopping_list_controller.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

// Lieu de rangement et date de péremption pour chaque article acheté.
class ShoppingListCheckoutScreen extends ConsumerStatefulWidget {
  const ShoppingListCheckoutScreen({
    super.key,
    required this.groupId,
    required this.items,
  });

  final int groupId;
  final List<ShoppingListItem> items;

  @override
  ConsumerState<ShoppingListCheckoutScreen> createState() =>
      _ShoppingListCheckoutScreenState();
}

class _ShoppingListCheckoutScreenState
    extends ConsumerState<ShoppingListCheckoutScreen> {
  late final Map<int, StorageLocation> _locations = {
    for (final item in widget.items) item.id: StorageLocation.fridge,
  };
  late final Map<int, DateTime> _expirationDates = {
    for (final item in widget.items)
      item.id: DateTime.now().add(const Duration(days: 7)),
  };
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _pickDate(int itemId) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDates[itemId],
      firstDate: now,
      lastDate: now.add(const Duration(days: 3 * 365)),
    );
    if (picked != null) setState(() => _expirationDates[itemId] = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await checkoutShoppingList(
        ref,
        groupId: widget.groupId,
        items: [
          for (final item in widget.items)
            CheckoutItem(
              itemId: item.id,
              storageLocation: _locations[item.id]!,
              expirationDate: _expirationDates[item.id]!,
            ),
        ],
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Valider mes achats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in widget.items)
            _CheckoutItemCard(
              item: item,
              location: _locations[item.id]!,
              expirationDate: _expirationDates[item.id]!,
              onLocationChanged: (location) =>
                  setState(() => _locations[item.id] = location),
              onPickDate: () => _pickDate(item.id),
            ),
          if (_errorMessage != null) FormErrorText(_errorMessage!),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: SubmitButtonContent(
              isSubmitting: _isSubmitting,
              label: Text(
                'Ajouter ${widget.items.length} aliment(s) au frigo/placard',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutItemCard extends StatelessWidget {
  const _CheckoutItemCard({
    required this.item,
    required this.location,
    required this.expirationDate,
    required this.onLocationChanged,
    required this.onPickDate,
  });

  final ShoppingListItem item;
  final StorageLocation location;
  final DateTime expirationDate;
  final ValueChanged<StorageLocation> onLocationChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              '${item.name} — ${item.quantity.toStringAsFixed(0)} ${item.unit}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SegmentedButton<StorageLocation>(
              segments: [
                for (final value in StorageLocation.values)
                  ButtonSegment(value: value, label: Text(value.label)),
              ],
              selected: {location},
              onSelectionChanged: (selection) =>
                  onLocationChanged(selection.first),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de péremption'),
              subtitle: Text(DateFormat('d/M/y').format(expirationDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: onPickDate,
            ),
          ],
        ),
      ),
    );
  }
}
