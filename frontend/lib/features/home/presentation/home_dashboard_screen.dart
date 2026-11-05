import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/auth/presentation/auth_controller.dart';
import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/features/home/presentation/widgets/add_meal_sheet.dart';
import 'package:keepmydiet/features/home/presentation/widgets/calorie_hero_card.dart';
import 'package:keepmydiet/features/home/presentation/widgets/dashboard_header.dart';
import 'package:keepmydiet/features/home/presentation/widgets/journal_date_nav.dart';
import 'package:keepmydiet/features/home/presentation/widgets/macro_card.dart';
import 'package:keepmydiet/features/home/presentation/widgets/shortcut_card.dart';
import 'package:keepmydiet/features/home/presentation/widgets/water_card.dart';
import 'package:keepmydiet/features/home/presentation/widgets/weight_card.dart';
import 'package:keepmydiet/features/nutrition/domain/profile.dart';
import 'package:keepmydiet/features/nutrition/presentation/daily_nutrition_log_controller.dart';
import 'package:keepmydiet/features/nutrition/presentation/nutrition_dashboard_screen.dart';
import 'package:keepmydiet/features/nutrition/presentation/profile_controller.dart';
import 'package:keepmydiet/features/nutrition/presentation/profile_form_screen.dart';
import 'package:keepmydiet/features/nutrition/presentation/profile_onboarding_screen.dart';
import 'package:keepmydiet/shared/home_navigation.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  // Le flag passe à true pendant l'inscription, avant que cet écran existe :
  // on lit donc sa valeur à chaque build (un ref.listen raterait ce cas).
  void _openOnboardingAfterRegister(BuildContext context, WidgetRef ref) {
    if (!ref.watch(justRegisteredProvider)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ref.read(justRegisteredProvider.notifier).set(false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileOnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _openOnboardingAfterRegister(context, ref);
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      body: profileAsync.toWidget(
        onRetry: () => ref.invalidate(profileControllerProvider),
        data: (profile) => profile == null
            ? const _NoProfileView()
            : _DashboardView(profile: profile),
      ),
    );
  }
}

class _NoProfileView extends StatelessWidget {
  const _NoProfileView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DashboardHeader(),
        const SizedBox(height: 48),
        const Text(
          'Crée ton profil pour voir ton tableau de bord nutrition.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileFormScreen())),
          child: const Text('Créer mon profil'),
        ),
        const SizedBox(height: 32),
        const WaterCard(),
      ],
    );
  }
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsControllerProvider).value ?? [];
    final dailyLogAsync = ref.watch(dailyNutritionLogControllerProvider);
    // En erreur, `.value` contient encore les chiffres du jour précédent.
    final dailyLog = dailyLogAsync.hasError ? null : dailyLogAsync.value;
    final showTab = ref.read(homeTabIndexProvider.notifier).show;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DashboardHeader(profile: profile),
        const SizedBox(height: 12),
        const JournalDateNav(),
        const SizedBox(height: 16),
        if (dailyLogAsync.hasError) ...[
          MessageBanner.error(
            message: 'Impossible de charger les données de ce jour.',
            icon: Icons.wifi_off_rounded,
            onRetry: () => ref.invalidate(dailyNutritionLogControllerProvider),
          ),
          const SizedBox(height: 16),
        ],
        CalorieHeroCard(
          profile: profile,
          caloriesConsumed: dailyLog?.caloriesConsumed ?? 0,
          onAdd: () => showAddMealSheet(context),
        ),
        const SizedBox(height: 24),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: MacroCard(
                icon: Icons.favorite_border,
                iconBg: AppColors.proteinBg,
                iconColor: AppColors.proteinIcon,
                barColor: AppColors.protein,
                label: 'Protéines',
                consumedG: dailyLog?.proteinConsumedG ?? 0,
                targetG: profile.proteinTargetG,
              ),
            ),
            Expanded(
              child: MacroCard(
                icon: Icons.grain,
                iconBg: AppColors.carbsBg,
                iconColor: AppColors.carbsIcon,
                barColor: AppColors.carbs,
                label: 'Glucides',
                consumedG: dailyLog?.carbConsumedG ?? 0,
                targetG: profile.carbTargetG,
              ),
            ),
            Expanded(
              child: MacroCard(
                icon: Icons.water_drop_outlined,
                iconBg: AppColors.fatBg,
                iconColor: AppColors.fatIcon,
                barColor: AppColors.fat,
                label: 'Lipides',
                consumedG: dailyLog?.fatConsumedG ?? 0,
                targetG: profile.fatTargetG,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const WaterCard(),
        const SizedBox(height: 24),
        WeightCard(profile: profile),
        const SizedBox(height: 24),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: ShortcutCard(
                icon: Icons.kitchen_outlined,
                iconBg: AppColors.brandLight,
                iconColor: AppColors.brandDark,
                label: groups.isEmpty ? 'Créer un groupe' : 'Frigo',
                subtitle: groups.isEmpty ? '' : groups.first.name,
                onTap: () => showTab(groups.isEmpty ? 3 : 1),
              ),
            ),
            Expanded(
              child: ShortcutCard(
                icon: Icons.restaurant_menu,
                iconBg: const Color(0xFFFFE8DD),
                iconColor: const Color(0xFFC8501C),
                label: 'Recettes',
                subtitle: 'Tes recettes',
                onTap: () => showTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NutritionDashboardScreen(),
              ),
            ),
            child: const Text('Voir le détail nutrition'),
          ),
        ),
      ],
    );
  }
}
