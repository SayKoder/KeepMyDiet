import 'package:flutter/material.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_step.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

// Les champs d'une étape du formulaire.
class StepFormRow {
  final instruction = TextEditingController();
  final durationMinutes = TextEditingController();

  void dispose() {
    instruction.dispose();
    durationMinutes.dispose();
  }

  // Une étape sans texte est ignorée (les étapes sont facultatives).
  RecipeStep? toStepOrNull() {
    final text = instruction.text.trim();
    if (text.isEmpty) return null;

    return RecipeStep(
      instruction: text,
      durationMinutes: int.tryParse(durationMinutes.text.trim()),
    );
  }
}

class StepFormCard extends StatelessWidget {
  const StepFormCard({
    super.key,
    required this.number,
    required this.row,
    required this.onRemove,
  });

  final int number;
  final StepFormRow row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 10,
        children: [
          Row(
            spacing: 12,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'ÉTAPE $number',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.errorText,
                tooltip: 'Retirer',
              ),
            ],
          ),
          TextField(
            controller: row.instruction,
            maxLines: null,
            decoration: const InputDecoration(labelText: 'Instruction'),
          ),
          NumberField(
            controller: row.durationMinutes,
            label: 'Durée — optionnel',
            decimal: false,
            suffix: 'min',
          ),
        ],
      ),
    );
  }
}
