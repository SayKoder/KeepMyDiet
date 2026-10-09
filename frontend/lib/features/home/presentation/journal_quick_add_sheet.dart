import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fridge/domain/food_reference.dart';
import '../../fridge/presentation/fridge_controller.dart';

/// Résultat saisi dans la feuille — toujours des valeurs *absolues* pour CET
/// ajout (pas des deltas déjà appliqués) : à l'appelant de décider quoi en
/// faire (ajouter au journal du jour, ou l'utiliser comme "autre chose" pour
/// un repas planifié — voir CreateOrUpdateMealPlanEntryLogProcessor côté
/// backend pour ce second cas).
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
}

/// `groupId` optionnel : sans groupe actif, on saute la recherche dans le
/// catalogue d'aliments (`foodCatalogProvider` est `.family` par groupe, pas
/// de catalogue "global") et on ne propose que la saisie manuelle.
Future<JournalQuickAddResult?> showJournalQuickAddSheet(BuildContext context, {int? groupId}) {
  return showModalBottomSheet<JournalQuickAddResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _JournalQuickAddSheet(groupId: groupId),
  );
}

class _JournalQuickAddSheet extends ConsumerStatefulWidget {
  const _JournalQuickAddSheet({this.groupId});

  final int? groupId;

  @override
  ConsumerState<_JournalQuickAddSheet> createState() => _JournalQuickAddSheetState();
}

class _JournalQuickAddSheetState extends ConsumerState<_JournalQuickAddSheet> {
  final _searchController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbController = TextEditingController();
  final _fatController = TextEditingController();
  FoodReference? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _selectFood(FoodReference food) {
    setState(() {
      _selected = food;
      _descriptionController.text = food.name;
    });
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _submit() {
    final double kcal;
    final double protein;
    final double carb;
    final double fat;

    final quantity = _selected == null ? null : _parse(_quantityController.text);
    if (_selected != null && quantity != null && quantity > 0) {
      final ratio = quantity / 100;
      kcal = _selected!.caloriesPer100g * ratio;
      protein = _selected!.proteinsPer100g * ratio;
      carb = _selected!.carbsPer100g * ratio;
      fat = _selected!.fatsPer100g * ratio;
    } else {
      kcal = _parse(_kcalController.text);
      protein = _parse(_proteinController.text);
      carb = _parse(_carbController.text);
      fat = _parse(_fatController.text);
    }

    if (kcal <= 0 && protein <= 0 && carb <= 0 && fat <= 0) {
      return;
    }

    Navigator.of(context).pop(JournalQuickAddResult(
      description: _descriptionController.text.trim().isEmpty ? 'Ajout manuel' : _descriptionController.text.trim(),
      kcal: kcal,
      proteinG: protein,
      carbG: carb,
      fatG: fat,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.groupId == null ? null : ref.watch(foodCatalogProvider(widget.groupId!)).value;
    final query = _searchController.text.trim().toLowerCase();
    final matches = query.isEmpty || catalog == null
        ? const <FoodReference>[]
        : catalog.where((f) => f.name.toLowerCase().contains(query)).take(6).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ajouter un aliment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (widget.groupId != null) ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(labelText: 'Chercher dans le placard', prefixIcon: Icon(Icons.search)),
                onChanged: (_) => setState(() {}),
              ),
              for (final food in matches)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(food.name),
                  subtitle: Text('${food.caloriesPer100g.round()} kcal / 100g'),
                  selected: _selected?.id == food.id,
                  onTap: () => _selectFood(food),
                ),
              const SizedBox(height: 12),
            ],
            if (_selected != null) ...[
              Text('Sélectionné : ${_selected!.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantité (g)'),
              ),
              TextButton(
                onPressed: () => setState(() => _selected = null),
                child: const Text('Saisir manuellement à la place'),
              ),
            ] else ...[
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kcalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'kcal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Protéines (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _carbController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Glucides (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Lipides (g)'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _submit, child: const Text('Ajouter')),
            ),
          ],
        ),
      ),
    );
  }
}
