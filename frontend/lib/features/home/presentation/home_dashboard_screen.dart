import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/home_navigation.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../nutrition/domain/profile.dart';
import '../../nutrition/presentation/nutrition_dashboard_screen.dart';
import '../../nutrition/presentation/profile_controller.dart';
import '../../nutrition/presentation/profile_form_screen.dart';
import '../../nutrition/presentation/water_goal_controller.dart';
import '../../nutrition/presentation/water_intake_controller.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: profileAsync.when(
        data: (profile) => profile == null
            ? _NoProfileScroll(
                onCreate: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileFormScreen()),
                ),
              )
            : _DashboardBody(profile: profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
    );
  }
}

class _WaterCard extends ConsumerWidget {
  const _WaterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(waterIntakeControllerProvider);
    final goalOverride = ref.watch(waterGoalControllerProvider).value?.goalMl;
    final profile = ref.watch(profileControllerProvider).value;

    // Surcharge manuelle (engrenage) si définie, sinon 35 mL/kg (repère
    // courant, fourchette 30-40 mL/kg habituelle) arrondi à 50 mL près.
    // 2000 mL par défaut si ni l'un ni l'autre n'existe.
    final defaultGoalMl = profile == null ? 2000 : ((profile.weightKg * 35) / 50).round() * 50;
    final goalMl = goalOverride ?? defaultGoalMl;
    final amountMl = waterAsync.value?.amountMl ?? 0;
    final progress = goalMl <= 0 ? 0.0 : (amountMl / goalMl).clamp(0.0, 1.0);
    final isLoading = waterAsync.isLoading && !waterAsync.hasValue;

    Future<void> add(int deltaMl) => ref.read(waterIntakeControllerProvider.notifier).add(deltaMl);

    final compactButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      textStyle: Theme.of(context).textTheme.labelMedium,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop_outlined, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Hydratation', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      isLoading ? '…' : '$amountMl / $goalMl mL',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    IconButton(
                      onPressed: () => _showEditGoalDialog(context, ref, goalMl),
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      tooltip: "Modifier l'objectif",
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 10),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: compactButtonStyle,
                    onPressed: isLoading || amountMl <= 0 ? null : () => add(-250),
                    child: const Text('-250 mL'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton.tonal(
                    style: compactButtonStyle,
                    onPressed: isLoading ? null : () => add(250),
                    child: const Text('+250 mL'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton(
                    style: compactButtonStyle,
                    onPressed: isLoading ? null : () => add(500),
                    child: const Text('+500 mL'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditGoalDialog(BuildContext context, WidgetRef ref, int currentGoalMl) async {
    final controller = TextEditingController(text: currentGoalMl.toString());

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Objectif d'hydratation"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Objectif (mL)'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(waterGoalControllerProvider.notifier).reset();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Réinitialiser (auto)'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final value = int.tryParse(controller.text);
              if (value == null || value <= 0) {
                return;
              }
              await ref.read(waterGoalControllerProvider.notifier).set(value);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _NoProfileScroll extends StatelessWidget {
  const _NoProfileScroll({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              const Text(
                "Crée ton profil pour voir ton tableau de bord nutrition.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onCreate, child: const Text('Créer mon profil')),
            ],
          ),
        ),
        const _WaterCard(),
      ],
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsControllerProvider).value ?? [];

    // Position de l'objectif entre le plancher de sécurité et le maintien
    // (TDEE) : contrairement à un vrai anneau "calories du jour", ceci ne
    // bouge pas dans la journée — pas de suivi de ce qui est mangé pour
    // l'instant (voir "Suivi diététique" dans CLAUDE.md).
    final span = profile.tdee - profile.calorieFloor;
    final ringValue = span <= 0 ? 0.0 : ((profile.calorieGoal - profile.calorieFloor) / span).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: ringValue,
                    strokeWidth: 14,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    const Text('kcal / jour visés'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _MacroCard(label: 'Protéines', grams: profile.proteinTargetG)),
            const SizedBox(width: 12),
            Expanded(child: _MacroCard(label: 'Glucides', grams: profile.carbTargetG)),
            const SizedBox(width: 12),
            Expanded(child: _MacroCard(label: 'Lipides', grams: profile.fatTargetG)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Repères indicatifs (répartition standard) — pas encore de suivi de "
          "ce qui est réellement mangé dans la journée.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 24),
        const _WaterCard(),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  profile.targetWeightKg == null
                      ? '${profile.weightKg.toStringAsFixed(1)} kg'
                      : '${profile.weightKg.toStringAsFixed(1)} kg → objectif ${profile.targetWeightKg!.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (profile.targetWeightKg != null) ...[
                  const SizedBox(height: 4),
                  Builder(builder: (context) {
                    final remainingKg = profile.weightKg - profile.targetWeightKg!;
                    final weeks = profile.estimatedWeeksToTarget;
                    final text = remainingKg <= 0
                        ? 'Objectif atteint 🎉'
                        : 'Reste ${remainingKg.toStringAsFixed(1)} kg'
                            '${weeks != null ? ' · environ $weeks semaines au rythme choisi' : ''}';

                    return Text(text, style: Theme.of(context).textTheme.bodySmall);
                  }),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _ShortcutCard(
                icon: Icons.kitchen_outlined,
                label: groups.isEmpty ? 'Créer un groupe' : 'Frigo',
                onTap: () => ref.read(homeTabIndexProvider.notifier).show(groups.isEmpty ? 3 : 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.restaurant_menu,
                label: 'Recettes',
                onTap: () => ref.read(homeTabIndexProvider.notifier).show(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NutritionDashboardScreen()),
            ),
            child: const Text('Voir le détail nutrition'),
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.label, required this.grams});

  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${grams.toStringAsFixed(0)} g', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
