import 'package:flutter/material.dart';

import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/nutrition/domain/profile.dart';
import 'package:keepmydiet/features/nutrition/presentation/profile_form_screen.dart';
import 'package:keepmydiet/shared/date_labels.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        formatDayLabel(DateTime.now()),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        'Bonjour !',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      trailing: IconButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileFormScreen(existingProfile: profile),
          ),
        ),
        icon: const Icon(Icons.person_outline, color: AppColors.brandDark),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.brandLight,
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}
