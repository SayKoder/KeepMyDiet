import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../shared/widgets/pill.dart';
import '../../../nutrition/domain/profile.dart';

class CalorieHeroCard extends StatelessWidget {
  const CalorieHeroCard({
    super.key,
    required this.profile,
    required this.caloriesConsumed,
    required this.onAdd,
  });

  final Profile profile;
  final int caloriesConsumed;
  final VoidCallback onAdd;

  String get _modeLabel {
    final deficit = profile.tdee - profile.calorieGoal;
    final weeklyLoss = profile.weeklyWeightLossGoalKg;

    if (deficit.abs() < 1) return 'Maintien';
    if (deficit < 0) return 'Prise';
    if (weeklyLoss == null) return 'Perte';
    return 'Perte · −${weeklyLoss.toStringAsFixed(2)} kg/sem.';
  }

  @override
  Widget build(BuildContext context) {
    final goal = profile.calorieGoal;
    final remaining = goal - caloriesConsumed;
    final faded = Colors.white.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.hero,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 18,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calories du jour',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Pill(
                label: _modeLabel,
                background: Colors.white.withValues(alpha: 0.12),
                foreground: Colors.white,
              ),
            ],
          ),
          Row(
            spacing: 20,
            children: [
              _CalorieRing(consumed: caloriesConsumed, goal: goal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    _HeroStat(
                      label: 'Objectif',
                      value: '${goal.toStringAsFixed(0)} kcal',
                    ),
                    _HeroStat(
                      label: 'Maintien (TDEE)',
                      value: '${profile.tdee.toStringAsFixed(0)} kcal',
                    ),
                    _HeroStat(
                      label: remaining >= 0 ? 'Restant' : 'Dépassement',
                      value: '${remaining.abs().toStringAsFixed(0)} kcal',
                      valueColor: AppColors.limeAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            'Mis à jour par tes repas validés et tes ajouts manuels.',
            style: TextStyle(fontSize: 12, height: 1.45, color: faded),
          ),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter un repas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({required this.consumed, required this.goal});

  final int consumed;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);

    return SizedBox.square(
      dimension: 156,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 14,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            color: AppColors.limeAccent,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$consumed',
                style: Theme.of(context).textTheme.displayMedium
                    ?.copyWith(color: Colors.white),
              ),
              Text(
                '/ ${goal.toStringAsFixed(0)} kcal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
