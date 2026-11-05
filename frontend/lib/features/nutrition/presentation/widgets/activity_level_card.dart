import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../domain/activity_level.dart';
import 'profile_section_card.dart';

class ActivityLevelCard extends StatelessWidget {
  const ActivityLevelCard({
    super.key,
    required this.activityLevel,
    required this.onChanged,
  });

  final ActivityLevel activityLevel;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      title: "NIVEAU D'ACTIVITÉ",
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final level in ActivityLevel.values)
              ChoiceChip(
                label: Text(level.shortLabel),
                selected: level == activityLevel,
                onSelected: (_) => onChanged(level),
                showCheckmark: false,
                shape: const StadiumBorder(),
                backgroundColor: Colors.white,
                selectedColor: AppColors.brandLight,
                side: BorderSide(
                  color: level == activityLevel
                      ? AppColors.brand
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: level == activityLevel
                      ? AppColors.brandDark
                      : AppColors.ink,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
