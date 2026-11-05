import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme.dart';
import '../../../../shared/widgets/segmented_pill.dart';
import '../../domain/sex.dart';
import 'compact_number_field.dart';
import 'profile_section_card.dart';

class ProfileBasicsCard extends StatelessWidget {
  const ProfileBasicsCard({
    super.key,
    required this.sex,
    required this.onSexChanged,
    required this.birthDate,
    required this.onPickBirthDate,
    required this.heightController,
    required this.weightController,
  });

  final Sex sex;
  final ValueChanged<Sex> onSexChanged;
  final DateTime? birthDate;
  final VoidCallback onPickBirthDate;
  final TextEditingController heightController;
  final TextEditingController weightController;

  @override
  Widget build(BuildContext context) {
    final date = birthDate;

    return ProfileSectionCard(
      title: 'TOI',
      children: [
        SegmentedPill<Sex>(
          values: Sex.values,
          selected: sex,
          labelOf: (value) => value.label,
          onChanged: onSexChanged,
          selectedColor: AppColors.ink,
          selectedTextColor: Colors.white,
        ),
        ListTile(
          onTap: onPickBirthDate,
          tileColor: AppColors.fieldFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          title: const Text(
            'Date de naissance',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          subtitle: Text(
            date == null
                ? 'Non renseignée'
                : DateFormat('dd/MM/y').format(date),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          trailing: const Icon(
            Icons.calendar_today_outlined,
            size: 20,
            color: AppColors.brand,
          ),
        ),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: CompactNumberField(
                label: 'Taille',
                unit: 'cm',
                controller: heightController,
              ),
            ),
            Expanded(
              child: CompactNumberField(
                label: 'Poids',
                unit: 'kg',
                controller: weightController,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
