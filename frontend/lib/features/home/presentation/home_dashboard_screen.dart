import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';

import '../../../shared/api_client.dart';
import '../../../shared/async_value_ui.dart';
import '../../../shared/home_navigation.dart';
import '../../../shared/white_card.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../meal_plan/domain/meal_plan_entry.dart';
import '../../meal_plan/domain/meal_plan_entry_status.dart';
import '../../meal_plan/domain/meal_type.dart';
import '../../meal_plan/presentation/add_meal_plan_entry_screen.dart';
import '../../meal_plan/presentation/meal_plan_controller.dart';
import '../../nutrition/domain/profile.dart';
import '../../nutrition/presentation/daily_nutrition_log_controller.dart';
import '../../nutrition/presentation/nutrition_dashboard_screen.dart';
import '../../nutrition/presentation/profile_controller.dart';
import '../../nutrition/presentation/profile_form_screen.dart';
import '../../nutrition/presentation/water_goal_controller.dart';
import '../../nutrition/presentation/water_intake_controller.dart';
import 'journal_date_controller.dart';
import 'journal_quick_add_sheet.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      body: profileAsync.toWidget(
        onRetry: () => ref.invalidate(profileControllerProvider),
        data: (profile) => profile == null
            ? _NoProfileScroll(
                onCreate: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileFormScreen(existingProfile: profile),
                  ),
                ),
              )
            : _DashboardBody(profile: profile),
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

    final defaultGoalMl = profile == null
        ? 2000
        : ((profile.weightKg * 35) / 50).round() * 50;
    final goalMl = goalOverride ?? defaultGoalMl;
    // `.value` reste rempli avec la valeur du jour précédent pendant un
    // AsyncError (comportement Riverpod voulu pour éviter un flash de
    // chargement) — sans ce `hasError`, changer de jour après un échec réseau
    // affichait silencieusement l'hydratation d'un AUTRE jour comme si elle
    // était à jour.
    final amountMl = waterAsync.hasError
        ? 0
        : (waterAsync.value?.amountMl ?? 0);
    final progress = goalMl <= 0 ? 0.0 : (amountMl / goalMl).clamp(0.0, 1.0);
    final isLoading = waterAsync.isLoading && !waterAsync.hasValue;

    Future<void> add(int deltaMl) =>
        ref.read(waterIntakeControllerProvider.notifier).add(deltaMl);

    return WhiteCard(
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
                    decoration: BoxDecoration(
                      color: AppColors.waterBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.water_drop_outlined,
                      size: 20,
                      color: AppColors.waterIcon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hydratation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: isLoading
                                  ? '… '
                                  : (waterAsync.hasError ? '— ' : '$amountMl '),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: waterAsync.hasError
                                    ? AppColors.errorText
                                    : AppColors.ink,
                              ),
                            ),
                            TextSpan(text: '/ $goalMl mL'),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showEditGoalDialog(context, ref, goalMl),
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                tooltip: "Modifier l'objectif",
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.fieldFill,
                  minimumSize: const Size(44, 44),
                ),
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
                  onPressed: isLoading || amountMl <= 0
                      ? null
                      : () => add(-250),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                    // Le padding horizontal par défaut du thème (`FilledButtonThemeData`,
                    // pensé pour un bouton pleine largeur) mangeait à lui seul
                    // plus de place que le texte dans ces boutons tiers de
                    // largeur — réduire seulement la police ne suffisait pas,
                    // il fallait aussi resserrer le padding.
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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

  Future<void> _showEditGoalDialog(
    BuildContext context,
    WidgetRef ref,
    int currentGoalMl,
  ) async {
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
              FilledButton(
                onPressed: onCreate,
                child: const Text('Créer mon profil'),
              ),
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
    final today = _capitalize(
      DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              today,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bonjour !',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileFormScreen(existingProfile: profile),
            ),
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

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _CalorieHeroCard extends StatelessWidget {
  const _CalorieHeroCard({
    required this.profile,
    required this.caloriesConsumed,
    required this.onAdd,
  });

  final Profile profile;
  final int caloriesConsumed;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final goal = profile.calorieGoal;
    final ringValue = goal <= 0
        ? 0.0
        : (caloriesConsumed / goal).clamp(0.0, 1.0);
    final remaining = goal - caloriesConsumed;
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
              const Text(
                'Calories du jour',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  modeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                        Text(
                          caloriesConsumed.toString(),
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
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroStat(
                      label: 'Objectif',
                      value: '${goal.toStringAsFixed(0)} kcal',
                    ),
                    const SizedBox(height: 12),
                    _HeroStat(
                      label: 'Maintien (TDEE)',
                      value: '${profile.tdee.toStringAsFixed(0)} kcal',
                    ),
                    const SizedBox(height: 12),
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
          const SizedBox(height: 18),
          Text(
            "Mis à jour par tes repas validés et tes ajouts manuels.",
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un repas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
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

class _JournalDateNav extends ConsumerWidget {
  const _JournalDateNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(journalDateProvider);
    final label = _capitalize(DateFormat('EEEE d MMMM', 'fr_FR').format(date));

    return Row(
      children: [
        IconButton(
          onPressed: () => ref.read(journalDateProvider.notifier).previousDay(),
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.fieldFill,
            minimumSize: const Size(40, 40),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        IconButton(
          onPressed: () => ref.read(journalDateProvider.notifier).nextDay(),
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.fieldFill,
            minimumSize: const Size(40, 40),
          ),
        ),
      ],
    );
  }
}

/// Feuille ouverte depuis le bouton "Ajouter un repas" de la carte calories :
/// soit répondre directement à un créneau planifié pas encore répondu pour le
/// jour affiché (réutilise _MealPromptCard telle quelle), soit "Petite faim"
/// pour un ajout libre sans lien avec le planning (réutilise la même feuille
/// que celle ouverte par "Autre chose").
class _AddChooserSheet extends ConsumerWidget {
  const _AddChooserSheet();

  /// Ne ferme PAS la pop-up avant d'avoir fini : réutiliser son `context`
  /// après un `pop()` précédent le laisserait démonté (plus de widget
  /// derrière), donc `context.mounted` resterait faux pour toujours et la
  /// suite (l'ajout au journal) ne s'exécuterait jamais silencieusement. On
  /// ferme la pop-up en tout dernier, une fois le travail terminé.
  Future<void> _openSnack(BuildContext context, WidgetRef ref) async {
    final groupId = ref.read(activeGroupProvider)?.id;
    final result = await showJournalQuickAddSheet(context, groupId: groupId);
    if (result == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(dailyNutritionLogControllerProvider.notifier)
          .add(
            deltaKcal: result.kcal.round(),
            deltaProteinG: result.proteinG,
            deltaCarbG: result.carbG,
            deltaFatG: result.fatG,
          );
    } on DioException catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e);
      }
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Choisir/créer une recette pour un des 3 repas de la journée crée un
  /// MealPlanEntry (AddMealPlanEntryScreen, déjà utilisé par l'écran de
  /// planning — on réutilise tel quel) PUIS le marque immédiatement "mangé"
  /// (respondToEntry) : contrairement à la planification classique, ici
  /// l'utilisateur dit "voilà ce que j'ai mangé", pas "voilà ce que je
  /// prévois" — pas de second Oui/Non à poser juste après l'avoir choisi.
  /// Même précaution que `_openSnack` : on pousse AddMealPlanEntryScreen
  /// PAR-DESSUS la pop-up encore ouverte (elle reste en dessous, invisible
  /// tant que l'écran plein écran la recouvre) plutôt que de la fermer
  /// avant — sinon `context` serait démonté au retour et `respondToEntry` ne
  /// s'exécuterait jamais. On ferme la pop-up en tout dernier.
  ///
  /// Un seul créneau par (jour, type de repas) : si `existing` n'est pas
  /// null, on demande confirmation puis on PATCH ce créneau (remplace sa
  /// recette) au lieu d'en créer un second — voir
  /// `AddMealPlanEntryScreen.existingEntryId` et JOURNAL.md.
  Future<void> _openMeal(
    BuildContext context,
    WidgetRef ref,
    MealType mealType, {
    MealPlanEntry? existing,
  }) async {
    final groupId = ref.read(activeGroupProvider)?.id;
    if (groupId == null) {
      return;
    }

    if (existing != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${mealType.label} déjà prévu'),
          content: Text(
            '${existing.recipe.name} est déjà prévu pour ce créneau. Le remplacer ?',
          ),
          // Un `Row` unique (plutôt que deux entrées dans `actions`) : passé
          // à l'`OverflowBar` interne de `AlertDialog`, deux boutons de taille
          // normale empilaient "Annuler" au-dessus de "Remplacer" dès que le
          // texte ne tenait pas sur une seule ligne faute de place — ici les
          // deux `Expanded` forcent le côte-à-côte quelle que soit la largeur.
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Remplacer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) {
        return;
      }
    }

    final journalDate = ref.read(journalDateProvider);

    final entry = await Navigator.of(context).push<MealPlanEntry>(
      MaterialPageRoute(
        builder: (_) => AddMealPlanEntryScreen(
          groupId: groupId,
          date: journalDate,
          mealType: mealType,
          existingEntryId: existing?.id,
        ),
      ),
    );
    if (entry == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(mealPlanControllerProvider)
          .respondToEntry(entryId: entry.id, status: MealPlanEntryStatus.eaten);
    } on DioException catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e);
      }
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final entries = activeGroup == null
        ? const <MealPlanEntry>[]
        : ref.watch(mealPlanEntriesForDateProvider(activeGroup.id)).value ??
              const <MealPlanEntry>[];
    final answeredEntryIds =
        (ref.watch(mealPlanEntryLogsProvider).value ?? const [])
            .map((log) => log.mealPlanEntryId)
            .toSet();
    final pendingEntries = entries
        .where((entry) => !answeredEntryIds.contains(entry.id))
        .toList();

    // Un seul créneau par type de repas pour le jour affiché : s'il en
    // existe déjà un, on le passe à `_openMeal` pour déclencher la
    // confirmation "Remplacer ?" au lieu d'en empiler un second.
    MealPlanEntry? existingFor(MealType type) {
      for (final entry in entries) {
        if (entry.mealType == type) return entry;
      }
      return null;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajouter un repas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'REPAS DU JOUR',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 10),
            _ChooserTile(
              icon: Icons.free_breakfast_outlined,
              label: 'Petit-déjeuner',
              onTap: () => _openMeal(
                context,
                ref,
                MealType.breakfast,
                existing: existingFor(MealType.breakfast),
              ),
            ),
            const SizedBox(height: 8),
            _ChooserTile(
              icon: Icons.lunch_dining_outlined,
              label: 'Déjeuner',
              onTap: () => _openMeal(
                context,
                ref,
                MealType.lunch,
                existing: existingFor(MealType.lunch),
              ),
            ),
            const SizedBox(height: 8),
            _ChooserTile(
              icon: Icons.dinner_dining_outlined,
              label: 'Dîner',
              onTap: () => _openMeal(
                context,
                ref,
                MealType.dinner,
                existing: existingFor(MealType.dinner),
              ),
            ),
            if (pendingEntries.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'REPAS PLANIFIÉS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 10),
              for (final entry in pendingEntries) _MealPromptCard(entry: entry),
            ],
            const SizedBox(height: 18),
            _ChooserTile(
              icon: Icons.fastfood_outlined,
              label: 'Petite faim',
              background: AppColors.brandLight,
              foreground: AppColors.brandDark,
              onTap: () => _openSnack(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChooserTile extends StatelessWidget {
  const _ChooserTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.background = AppColors.fieldFill,
    this.foreground = AppColors.ink,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealPromptCard extends ConsumerWidget {
  const _MealPromptCard({required this.entry});

  final MealPlanEntry entry;

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    MealPlanEntryStatus status,
  ) async {
    JournalQuickAddResult? replacement;

    if (status == MealPlanEntryStatus.replaced) {
      final groupId = ref.read(activeGroupProvider)?.id;
      replacement = await showJournalQuickAddSheet(context, groupId: groupId);
      if (replacement == null || !context.mounted) {
        return;
      }
    }

    try {
      await ref
          .read(mealPlanControllerProvider)
          .respondToEntry(
            entryId: entry.id,
            status: status,
            replacementDescription: replacement?.description,
            replacementCalories: replacement?.kcal,
            replacementProteinG: replacement?.proteinG,
            replacementCarbG: replacement?.carbG,
            replacementFatG: replacement?.fatG,
          );
    } on DioException catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WhiteCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entry.mealType.label} — ${entry.recipe.name} ?',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _respond(context, ref, MealPlanEntryStatus.eaten),
                  child: const Text('Oui'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _respond(context, ref, MealPlanEntryStatus.skipped),
                  child: const Text('Non'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _respond(context, ref, MealPlanEntryStatus.replaced),
                  child: const Text('Autre chose'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataErrorBanner extends StatelessWidget {
  const _DataErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: AppColors.errorText,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Impossible de charger les données de ce jour.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.errorText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorText,
              padding: EdgeInsets.zero,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsControllerProvider).value ?? [];
    final dailyLogAsync = ref.watch(dailyNutritionLogControllerProvider);
    // `.value` reste rempli avec la valeur du jour précédent pendant un
    // AsyncError (comportement Riverpod voulu pour éviter un flash de
    // chargement entre deux jours) — sans ce `hasError`, un simple raté réseau
    // pendant la navigation laissait les calories/macros du jour précédent
    // affichées comme si elles étaient celles du nouveau jour sélectionné.
    final dailyLog = dailyLogAsync.hasError ? null : dailyLogAsync.value;
    final caloriesConsumed = dailyLog?.caloriesConsumed ?? 0;
    final proteinConsumedG = dailyLog?.proteinConsumedG ?? 0.0;
    final carbConsumedG = dailyLog?.carbConsumedG ?? 0.0;
    final fatConsumedG = dailyLog?.fatConsumedG ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Header(profile: profile),
        const SizedBox(height: 12),
        const _JournalDateNav(),
        const SizedBox(height: 16),
        if (dailyLogAsync.hasError) ...[
          _DataErrorBanner(
            onRetry: () => ref.invalidate(dailyNutritionLogControllerProvider),
          ),
          const SizedBox(height: 16),
        ],
        _CalorieHeroCard(
          profile: profile,
          caloriesConsumed: caloriesConsumed,
          onAdd: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => const _AddChooserSheet(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MacroCard(
                icon: Icons.favorite_border,
                iconBg: AppColors.proteinBg,
                iconColor: AppColors.proteinIcon,
                barColor: AppColors.protein,
                label: 'Protéines',
                consumedG: proteinConsumedG,
                targetG: profile.proteinTargetG,
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
                consumedG: carbConsumedG,
                targetG: profile.carbTargetG,
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
                consumedG: fatConsumedG,
                targetG: profile.fatTargetG,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _WaterCard(),
        const SizedBox(height: 24),
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Poids',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (profile.estimatedWeeksToTarget != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '~${profile.estimatedWeeksToTarget} semaines',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandDark,
                        ),
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
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppColors.ink,
                    ),
                  ),
                  const Text(
                    ' kg',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (profile.targetWeightKg != null) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: AppColors.iconMuted,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${profile.targetWeightKg!.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ],
                ],
              ),
              if (profile.targetWeightKg != null) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final remainingKg =
                        profile.weightKg - profile.targetWeightKg!;
                    final text = remainingKg <= 0
                        ? 'Objectif atteint 🎉'
                        : 'Reste ${remainingKg.toStringAsFixed(1)} kg au rythme choisi';
                    return Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
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
                onTap: () => ref
                    .read(homeTabIndexProvider.notifier)
                    .show(groups.isEmpty ? 3 : 1),
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

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.barColor,
    required this.label,
    required this.consumedG,
    required this.targetG,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color barColor;
  final String label;
  final double consumedG;
  final double targetG;

  @override
  Widget build(BuildContext context) {
    final progress = targetG <= 0 ? 0.0 : (consumedG / targetG).clamp(0.0, 1.0);

    return WhiteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            '${consumedG.round()} g',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '/ ${targetG.round()} g',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.iconMuted,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
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
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
