import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_ui.dart';
import '../domain/profile.dart';
import 'profile_controller.dart';
import 'profile_form_screen.dart';

class NutritionDashboardScreen extends ConsumerWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: profileAsync.toWidget(
        onRetry: () => ref.invalidate(profileControllerProvider),
        data: (profile) => profile == null
            ? const _NoProfileView()
            : _DashboardView(profile: profile),
      ),
    );
  }
}

void _openProfileForm(BuildContext context, [Profile? profile]) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ProfileFormScreen(existingProfile: profile),
    ),
  );
}

class _NoProfileView extends StatelessWidget {
  const _NoProfileView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Text(
              'Crée ton profil pour calculer tes besoins caloriques.',
              textAlign: TextAlign.center,
            ),
            FilledButton(
              onPressed: () => _openProfileForm(context),
              child: const Text('Créer mon profil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final weeks = profile.estimatedWeeksToTarget;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: SizedBox.square(
            dimension: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profile.calorieGoal.toStringAsFixed(0),
                      style: textTheme.headlineMedium,
                    ),
                    const Text('kcal / jour (objectif)'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _StatCard(
                label: 'Métabolisme de base',
                value: profile.bmr,
              ),
            ),
            Expanded(
              child: _StatCard(
                label: 'Dépense totale (TDEE)',
                value: profile.tdee,
              ),
            ),
            Expanded(
              child: _StatCard(
                label: 'Plancher de sécurité',
                value: profile.calorieFloor,
              ),
            ),
          ],
        ),
        if (weeks != null) ...[
          const SizedBox(height: 16),
          Text(
            'Environ $weeks semaines pour atteindre '
            '${profile.targetWeightKg!.toStringAsFixed(1)}kg au rythme choisi.',
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        Text(
          '${profile.age} ans · ${profile.heightCm.toStringAsFixed(0)}cm · '
          '${profile.weightKg.toStringAsFixed(1)}kg',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => _openProfileForm(context, profile),
            child: const Text('Modifier mon profil'),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 4,
          children: [
            Text(
              '${value.toStringAsFixed(0)} kcal',
              style: textTheme.titleLarge,
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
