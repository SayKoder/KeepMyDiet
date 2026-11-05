import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/nutrition/domain/activity_level.dart';
import 'package:keepmydiet/features/nutrition/domain/sex.dart';
import 'package:keepmydiet/features/nutrition/presentation/profile_controller.dart';
import 'package:keepmydiet/features/nutrition/presentation/profile_input.dart';
import 'package:keepmydiet/features/nutrition/presentation/widgets/activity_level_card.dart';
import 'package:keepmydiet/features/nutrition/presentation/widgets/goal_card.dart';
import 'package:keepmydiet/features/nutrition/presentation/widgets/onboarding_reveal.dart';
import 'package:keepmydiet/features/nutrition/presentation/widgets/profile_basics_card.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

// Parcours guidé en 3 étapes après l'inscription, avec les mêmes cartes que
// le formulaire de profil.
class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen> {
  static const _stepCount = 3;

  final _pageController = PageController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  int _step = 0;
  Sex _sex = Sex.male;
  DateTime? _birthDate;
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  bool _customPace = false;
  double _weeklyGoal = 0.5;
  bool _isSubmitting = false;
  bool _isDone = false;
  String? _error;

  bool get _isLastStep => _step == _stepCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _goToStep(int step) async {
    setState(() => _error = null);
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _step = step);
  }

  String? _basicsError() => validateBasics(
    birthDate: _birthDate,
    height: _heightController.text,
    weight: _weightController.text,
  );

  void _next() {
    final error = _step == 0 ? _basicsError() : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _goToStep(_step + 1);
  }

  Future<void> _finish() async {
    final error = validateTargetWeight(_targetWeightController.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_basicsError() != null) {
      await _goToStep(0);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref
          .read(profileControllerProvider.notifier)
          .create(
            sex: _sex,
            birthDate: _birthDate!,
            heightCm: parsePositive(_heightController.text)!,
            weightKg: parsePositive(_weightController.text)!,
            activityLevel: _activityLevel,
            targetWeightKg: parsePositive(_targetWeightController.text),
            weeklyWeightLossGoalKg: _customPace ? _weeklyGoal : null,
          );
      if (!mounted) return;
      setState(() => _isDone = true);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) revealScreenBelow(context);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = '$e';
      });
    }
  }

  String _guidance() {
    if (_step == 0) {
      return 'Ces infos servent à calculer ton métabolisme de base.';
    }
    if (_step == 1) {
      return switch (_activityLevel) {
        ActivityLevel.sedentary || ActivityLevel.light =>
          "Peu de dépense physique : on resserre un peu plus l'objectif "
              'calorique.',
        ActivityLevel.moderate =>
          'Un rythme équilibré, le plus courant au quotidien.',
        ActivityLevel.active || ActivityLevel.veryActive =>
          'Beaucoup de dépense physique : ton objectif calorique sera plus '
              'large.',
      };
    }
    if (!_customPace) {
      return "Déficit automatique de 20% sous ton métabolisme d'entretien — "
          'simple et sans réflexion à avoir.';
    }
    if (_weeklyGoal <= 0.4) {
      return 'Rythme doux : perte lente mais plus confortable à tenir dans la '
          'durée.';
    }
    if (_weeklyGoal <= 0.75) {
      return 'Rythme modéré : bon compromis entre vitesse et confort.';
    }
    return 'Rythme soutenu : résultats plus rapides, demande plus de rigueur.';
  }

  List<Widget> get _steps => [
    ProfileBasicsCard(
      sex: _sex,
      onSexChanged: (value) => setState(() => _sex = value),
      birthDate: _birthDate,
      onPickBirthDate: _pickBirthDate,
      heightController: _heightController,
      weightController: _weightController,
    ),
    ActivityLevelCard(
      activityLevel: _activityLevel,
      onChanged: (value) => setState(() => _activityLevel = value),
    ),
    GoalCard(
      targetWeightController: _targetWeightController,
      customPace: _customPace,
      onCustomPaceChanged: (value) => setState(() => _customPace = value),
      weeklyGoal: _weeklyGoal,
      onWeeklyGoalChanged: (value) => setState(() => _weeklyGoal = value),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isDone) return const OnboardingSuccessView();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text(
                    'Configure ton profil',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  _StepProgress(step: _step, count: _stepCount),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _guidance(),
                      key: ValueKey(_guidance()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final step in _steps)
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: step,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                spacing: 10,
                children: [
                  if (_error != null) MessageBanner.error(message: _error!),
                  Row(
                    spacing: 12,
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _goToStep(_step - 1),
                            child: const Text('Précédent'),
                          ),
                        ),
                      Expanded(
                        flex: _step > 0 ? 2 : 1,
                        child: FilledButton(
                          onPressed: _isSubmitting
                              ? null
                              : (_isLastStep ? _finish : _next),
                          child: SubmitButtonContent(
                            isSubmitting: _isSubmitting,
                            label: Text(_isLastStep ? 'Terminé' : 'Suivant'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.count});

  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: LinearProgressIndicator(
              value: i <= step ? 1 : 0,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: AppColors.fieldFill,
              color: AppColors.brand,
            ),
          ),
      ],
    );
  }
}
