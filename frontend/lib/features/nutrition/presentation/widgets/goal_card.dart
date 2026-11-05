import 'package:flutter/material.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/nutrition/presentation/widgets/compact_number_field.dart';
import 'package:keepmydiet/features/nutrition/presentation/widgets/profile_section_card.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.targetWeightController,
    required this.customPace,
    required this.onCustomPaceChanged,
    required this.weeklyGoal,
    required this.onWeeklyGoalChanged,
  });

  final TextEditingController targetWeightController;
  final bool customPace;
  final ValueChanged<bool> onCustomPaceChanged;
  final double weeklyGoal;
  final ValueChanged<double> onWeeklyGoalChanged;

  static const _paceSteps = ['0.25', '0.50', '0.75', '1.00'];
  static const _hintStyle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      title: 'OBJECTIF',
      children: [
        CompactNumberField(
          label: 'Poids visé — optionnel',
          unit: 'kg',
          controller: targetWeightController,
        ),
        const Text(
          "Sert uniquement à estimer le délai, n'influence pas l'objectif "
          'calorique.',
          style: _hintStyle,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: customPace,
          onChanged: onCustomPaceChanged,
          title: const Text(
            'Rythme de perte personnalisé',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Sinon : déficit fixe de 20% du maintien.',
            style: _hintStyle,
          ),
        ),
        if (customPace) ...[
          Text(
            '${weeklyGoal.toStringAsFixed(2)} kg / semaine',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          Column(
            children: [
              Slider(
                value: weeklyGoal,
                min: 0.25,
                max: 1,
                divisions: _paceSteps.length - 1,
                label: '${weeklyGoal.toStringAsFixed(2)} kg',
                onChanged: onWeeklyGoalChanged,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final step in _paceSteps)
                      Text(step, style: _hintStyle.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const MessageBanner.info(
            message:
                "L'objectif ne descendra jamais sous ton métabolisme de base "
                '(plancher de sécurité).',
          ),
        ],
      ],
    );
  }
}
