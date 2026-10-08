import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';

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
      body: profileAsync.when(
        data: (profile) => profile == null
            ? _NoProfileScroll(
                onCreate: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfileFormScreen(existingProfile: profile)),
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

    final defaultGoalMl = profile == null ? 2000 : ((profile.weightKg * 35) / 50).round() * 50;
    final goalMl = goalOverride ?? defaultGoalMl;
    final amountMl = waterAsync.value?.amountMl ?? 0;
    final progress = goalMl <= 0 ? 0.0 : (amountMl / goalMl).clamp(0.0, 1.0);
    final isLoading = waterAsync.isLoading && !waterAsync.hasValue;

    Future<void> add(int deltaMl) => ref.read(waterIntakeControllerProvider.notifier).add(deltaMl);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.waterBg, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.water_drop_outlined, size: 20, color: AppColors.waterIcon),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hydratation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: isLoading ? '… ' : '$amountMl ',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
                            ),
                            TextSpan(text: '/ $goalMl mL'),
                          ],
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showEditGoalDialog(context, ref, goalMl),
                icon: const Icon(Icons.settings_outlined, size: 18, color: AppColors.textSecondary),
                tooltip: "Modifier l'objectif",
                style: IconButton.styleFrom(backgroundColor: AppColors.fieldFill, minimumSize: const Size(44, 44)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 10; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 9 ? 0 : 5),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: _segmentColor(progress, i),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading || amountMl <= 0 ? null : () => add(-250),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  child: const Text('−250'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: isLoading ? null : () => add(250),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.waterBg,
                    // Pas dans AppColors (seul usage dans toute l'appli) : pas
                    // la peine d'ajouter un token pour une seule ligne.
                    foregroundColor: const Color(0xFF135F99),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('+250 mL'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: isLoading ? null : () => add(500),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.waterIcon,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('+500 mL'),
                ),
              ),
            ],
          ),
        ],
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

Color _segmentColor(double progress, int index) {
  final segmentStart = index / 10;
  final segmentEnd = (index + 1) / 10;
  if (progress >= segmentEnd) return AppColors.water;
  if (progress > segmentStart) return const Color(0xFFA9D6F8);
  return const Color(0xFFE6F1FB);
}


class _NoProfileScroll extends StatelessWidget {
  const _NoProfileScroll({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _Header(),
        const SizedBox(height: 16),
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

class _Header extends StatelessWidget {
  const _Header({this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final today = _capitalize(DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(today, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text('Bonjour !', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProfileFormScreen(existingProfile: profile)),
          ),
          icon: const Icon(Icons.person_outline, color: AppColors.brandDark),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.brandLight,
            minimumSize: const Size(48, 48),
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _CalorieHeroCard extends StatelessWidget {
  const _CalorieHeroCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final span = profile.tdee - profile.calorieFloor;
    final ringValue = span <= 0 ? 0.0 : ((profile.calorieGoal - profile.calorieFloor) / span).clamp(0.0, 1.0);
    final deficit = profile.tdee - profile.calorieGoal;

    final String modeLabel;
    if (deficit.abs() < 1) {
      modeLabel = 'Maintien';
    } else if (deficit > 0) {
      modeLabel = profile.weeklyWeightLossGoalKg != null
          ? 'Perte · −${profile.weeklyWeightLossGoalKg!.toStringAsFixed(2)} kg/sem.'
          : 'Perte';
    } else {
      modeLabel = 'Prise';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.hero,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Objectif calorique', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                child: Text(modeLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 156,
                height: 156,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 156,
                      height: 156,
                      child: CircularProgressIndicator(
                        value: ringValue,
                        strokeWidth: 14,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        color: AppColors.limeAccent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(profile.calorieGoal.toStringAsFixed(0), style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white)),
                        Text('kcal / jour', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.75))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroStat(label: 'Maintien (TDEE)', value: '${profile.tdee.toStringAsFixed(0)} kcal'),
                    const SizedBox(height: 12),
                    _HeroStat(label: 'Plancher sécurité', value: '${profile.calorieFloor.toStringAsFixed(0)} kcal'),
                    const SizedBox(height: 12),
                    _HeroStat(label: 'Déficit', value: '${deficit >= 0 ? '−' : '+'}${deficit.abs().toStringAsFixed(0)} kcal', valueColor: AppColors.limeAccent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "L'anneau situe ton objectif entre le plancher et le maintien.",
            style: TextStyle(fontSize: 12, height: 1.45, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value, this.valueColor = Colors.white});

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.72))),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor)),
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Header(profile: profile),
        const SizedBox(height: 16),
        _CalorieHeroCard(profile: profile),
        const SizedBox(height: 24),
        Builder(builder: (context) {
          final totalKcal = profile.calorieGoal <= 0 ? 1.0 : profile.calorieGoal;
          // 4 kcal/g pour protéines et glucides, 9 kcal/g pour les lipides — les
          // vrais facteurs nutritionnels, pas une proportion inventée : la largeur
          // de chaque barre reflète la vraie part de calories de ce macro, calculée
          // à partir des grammes réels (peut différer de l'exemple 30/45/25 de la
          // maquette, qui n'est qu'un exemple statique).
          return Row(
            children: [
              Expanded(
                child: _MacroCard(
                  icon: Icons.favorite_border,
                  iconBg: AppColors.proteinBg,
                  iconColor: AppColors.proteinIcon,
                  barColor: AppColors.protein,
                  label: 'Protéines',
                  grams: profile.proteinTargetG,
                  shareOfCalories: (profile.proteinTargetG * 4) / totalKcal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroCard(
                  icon: Icons.grain,
                  iconBg: AppColors.carbsBg,
                  iconColor: AppColors.carbsIcon,
                  barColor: AppColors.carbs,
                  label: 'Glucides',
                  grams: profile.carbTargetG,
                  shareOfCalories: (profile.carbTargetG * 4) / totalKcal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroCard(
                  icon: Icons.water_drop_outlined,
                  iconBg: AppColors.fatBg,
                  iconColor: AppColors.fatIcon,
                  barColor: AppColors.fat,
                  label: 'Lipides',
                  grams: profile.fatTargetG,
                  shareOfCalories: (profile.fatTargetG * 9) / totalKcal,
                ),
              ),
            ],
          );
        }),
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
        Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Poids', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (profile.estimatedWeeksToTarget != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '~${profile.estimatedWeeksToTarget} semaines',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandDark),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  profile.weightKg.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: AppColors.ink),
                ),
                const Text(' kg', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                if (profile.targetWeightKg != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 18, color: AppColors.iconMuted),
                  const SizedBox(width: 10),
                  Text(
                    '${profile.targetWeightKg!.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brandDark),
                  ),
                ],
              ],
            ),
            if (profile.targetWeightKg != null) ...[
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final remainingKg = profile.weightKg - profile.targetWeightKg!;
                final text = remainingKg <= 0
                    ? 'Objectif atteint 🎉'
                    : 'Reste ${remainingKg.toStringAsFixed(1)} kg au rythme choisi';
                return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
              }),
            ],
          ],
        ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _ShortcutCard(
                icon: Icons.kitchen_outlined,
                iconBg: AppColors.brandLight,
                iconColor: AppColors.brandDark,
                label: groups.isEmpty ? 'Créer un groupe' : 'Frigo',
                subtitle: groups.isEmpty ? '' : groups.first.name,
                onTap: () => ref.read(homeTabIndexProvider.notifier).show(groups.isEmpty ? 3 : 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.restaurant_menu,
                iconBg: const Color(0xFFFFE8DD),
                iconColor: const Color(0xFFC8501C),
                label: 'Recettes',
                subtitle: 'Tes recettes',
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
  const _MacroCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.barColor,
    required this.label,
    required this.grams,
    required this.shareOfCalories,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color barColor;
  final String label;
  final double grams;
  final double shareOfCalories;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text('${grams.toStringAsFixed(0)} g', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.ink)),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: shareOfCalories.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.fieldFill,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}


class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 14),
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

