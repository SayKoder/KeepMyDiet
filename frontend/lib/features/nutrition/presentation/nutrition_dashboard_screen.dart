import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/async_value_ui.dart';
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
        data: (profile) => profile == null
            ? _NoProfileView(
                onCreate: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileFormScreen()),
                ),
              )
            : _DashboardView(profile: profile),
      ),
    );
  }
}

class _NoProfileView extends StatelessWidget {
  const _NoProfileView({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Crée ton profil pour calculer tes besoins caloriques.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Anneau décoratif (inspiration Samsung Health) : pas encore
                // un vrai pourcentage de progression, faute d'un suivi des
                // calories consommées dans la journée (pas encore construit,
                // voir CLAUDE.md "Suivi diététique").
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.calorieGoal.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineMedium,
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
          children: [
            Expanded(
              child: _StatCard(
                label: 'Métabolisme de base',
                value: profile.bmr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Dépense totale (TDEE)',
                value: profile.tdee,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Plancher de sécurité',
                value: profile.calorieFloor,
              ),
            ),
          ],
        ),
        if (profile.estimatedWeeksToTarget != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Environ ${profile.estimatedWeeksToTarget} semaines pour atteindre '
              '${profile.targetWeightKg!.toStringAsFixed(1)}kg au rythme choisi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          '${profile.age} ans · ${profile.heightCm.toStringAsFixed(0)}cm · ${profile.weightKg.toStringAsFixed(1)}kg',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfileFormScreen(existingProfile: profile),
              ),
            ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${value.toStringAsFixed(0)} kcal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
