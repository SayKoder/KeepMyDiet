import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/number_field.dart';
import '../../fridge/domain/food_reference.dart';
import '../../fridge/presentation/fridge_controller.dart';

// Valeurs absolues pour CET ajout : l'appelant décide quoi en faire.
class JournalQuickAddResult {
  const JournalQuickAddResult({
    required this.description,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final String description;
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;

  bool get isEmpty => kcal <= 0 && proteinG <= 0 && carbG <= 0 && fatG <= 0;
}

// Sans groupe, pas de catalogue d'aliments : saisie manuelle uniquement.
Future<JournalQuickAddResult?> showJournalQuickAddSheet(
  BuildContext context, {
  int? groupId,
}) {
  return showModalBottomSheet<JournalQuickAddResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _JournalQuickAddSheet(groupId: groupId),
  );
}

class _JournalQuickAddSheet extends ConsumerStatefulWidget {
  const _JournalQuickAddSheet({this.groupId});

  final int? groupId;

  @override
  ConsumerState<_JournalQuickAddSheet> createState() =>
      _JournalQuickAddSheetState();
}

class _JournalQuickAddSheetState extends ConsumerState<_JournalQuickAddSheet> {
  final _search = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carb = TextEditingController();
  final _fat = TextEditingController();
  FoodReference? _selected;

  @override
  void dispose() {
    for (final controller in [
      _search,
      _description,
      _quantity,
      _kcal,
      _protein,
      _carb,
      _fat,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;

  JournalQuickAddResult _buildResult() {
    final description = _description.text.trim();
    final food = _selected;
    final quantity = _parse(_quantity);

    if (food != null && quantity > 0) {
      final ratio = quantity / 100;
      return JournalQuickAddResult(
        description: food.name,
        kcal: food.caloriesPer100g * ratio,
        proteinG: food.proteinsPer100g * ratio,
        carbG: food.carbsPer100g * ratio,
        fatG: food.fatsPer100g * ratio,
      );
    }

    return JournalQuickAddResult(
      description: description.isEmpty ? 'Ajout manuel' : description,
      kcal: _parse(_kcal),
      proteinG: _parse(_protein),
      carbG: _parse(_carb),
      fatG: _parse(_fat),
    );
  }

  void _submit() {
    final result = _buildResult();
    if (!result.isEmpty) Navigator.of(context).pop(result);
  }

  List<FoodReference> _matches() {
    final groupId = widget.groupId;
    final query = _search.text.trim().toLowerCase();
    if (groupId == null || query.isEmpty) return const [];

    final catalog = ref.watch(foodCatalogProvider(groupId)).value ?? const [];
    return catalog
        .where((food) => food.name.toLowerCase().contains(query))
        .take(6)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            'Ajouter un aliment',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (widget.groupId != null) ...[
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Chercher dans le placard',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            for (final food in _matches())
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(food.name),
                subtitle: Text('${food.caloriesPer100g.round()} kcal / 100g'),
                selected: selected?.id == food.id,
                onTap: () => setState(() => _selected = food),
              ),
          ],
          if (selected != null) ...[
            Text(
              'Sélectionné : ${selected.name}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            NumberField(controller: _quantity, label: 'Quantité (g)'),
            TextButton(
              onPressed: () => setState(() => _selected = null),
              child: const Text('Saisir manuellement à la place'),
            ),
          ] else ...[
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: NumberField(controller: _kcal, label: 'kcal'),
                ),
                Expanded(
                  child: NumberField(
                    controller: _protein,
                    label: 'Protéines (g)',
                  ),
                ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: NumberField(controller: _carb, label: 'Glucides (g)'),
                ),
                Expanded(
                  child: NumberField(controller: _fat, label: 'Lipides (g)'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(onPressed: _submit, child: const Text('Ajouter')),
        ],
      ),
    );
  }
}
