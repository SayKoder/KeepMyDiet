import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/form_error_text.dart';
import '../../../shared/submit_button_content.dart';
import '../../fridge/domain/storage_location.dart';
import '../data/shopping_list_api_client.dart';
import '../domain/shopping_list_item.dart';
import 'shopping_list_controller.dart';

/// Une ligne par item sélectionné : lieu de stockage + DLC, obligatoires
/// (CLAUDE.md : "ajoutés au frigo ou au placard... avec leur DLC (saisie
/// manuelle...)" — pas d'estimation automatique par catégorie en v1, voir
/// JOURNAL.md). Valide tout d'un coup via `checkout`.
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
      initialDate: _expirationDates[itemId] ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3 * 365)),
    );
    if (picked != null) {
      setState(() => _expirationDates[itemId] = picked);
    }
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
        items: widget.items
            .map(
              (item) => CheckoutItem(
                itemId: item.id,
                storageLocation: _locations[item.id]!,
                expirationDate: _expirationDates[item.id]!,
              ),
            )
            .toList(),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Valider mes achats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in widget.items) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name} — ${item.quantity.toStringAsFixed(0)} ${item.unit}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<StorageLocation>(
                      segments: StorageLocation.values
                          .map(
                            (location) => ButtonSegment(
                              value: location,
                              label: Text(location.label),
                            ),
                          )
                          .toList(),
                      selected: {_locations[item.id]!},
                      onSelectionChanged: (selection) =>
                          setState(() => _locations[item.id] = selection.first),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date de péremption'),
                      subtitle: Text(
                        '${_expirationDates[item.id]!.day}/${_expirationDates[item.id]!.month}/${_expirationDates[item.id]!.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _pickDate(item.id),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
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
