import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../shared/widgets/pill.dart';
import '../../../../shared/widgets/white_card.dart';
import '../../../nutrition/domain/profile.dart';

class WeightCard extends StatelessWidget {
  const WeightCard({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final target = profile.targetWeightKg;
    final weeks = profile.estimatedWeeksToTarget;

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Poids',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (weeks != null)
                Pill(
                  label: '~$weeks semaines',
                  background: AppColors.brandLight,
                  foreground: AppColors.brandDark,
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 10,
            children: [
              Text.rich(
                TextSpan(
                  text: profile.weightKg.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                  children: const [
                    TextSpan(
                      text: ' kg',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (target != null) ...[
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: AppColors.iconMuted,
                ),
                Text(
                  '${target.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDark,
                  ),
                ),
              ],
            ],
          ),
          if (target != null)
            Text(
              _remainingLabel(profile.weightKg - target),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  String _remainingLabel(double remainingKg) => remainingKg <= 0
      ? 'Objectif atteint 🎉'
      : 'Reste ${remainingKg.toStringAsFixed(1)} kg au rythme choisi';
}
