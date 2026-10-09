import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../shared/submit_button_content.dart';
import '../domain/activity_level.dart';
import '../domain/sex.dart';
import 'profile_controller.dart';
import 'profile_form_screen.dart';

/// Parcours guidé en 3 étapes affiché juste après la création de compte
/// (voir `justRegisteredProvider` dans `auth_controller.dart`) — remplace le
/// formulaire complet unique (`ProfileFormScreen`, toujours utilisé pour
/// *modifier* un profil existant) par un passage plus doux, un bloc de champs
/// à la fois. Les 3 cartes affichées sont les mêmes `ProfileBasicsCard` /
/// `ActivityLevelCard` / `GoalCard` que le formulaire complet : rien n'est
/// dupliqué, seule la présentation (une étape à la fois + `PageView`) change.
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
  double _weeklyWeightLossGoalKg = 0.5;
  bool _isSubmitting = false;
  bool _isDone = false;
  String? _stepError;

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
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _goToStep(int step) async {
    setState(() => _stepError = null);
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _step = step);
  }

  void _next() {
    if (_step == 0) {
      if (_birthDate == null) {
        setState(() => _stepError = 'Choisis ta date de naissance.');
        return;
      }
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);
      if (height == null || height <= 0 || weight == null || weight <= 0) {
        setState(
          () =>
              _stepError = 'Taille et poids doivent être des nombres positifs.',
        );
        return;
      }
    }
    _goToStep(_step + 1);
  }

  Future<void> _finish() async {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final targetWeightText = _targetWeightController.text.trim();
    final targetWeight = targetWeightText.isEmpty
        ? null
        : double.tryParse(targetWeightText);

    if (targetWeightText.isNotEmpty &&
        (targetWeight == null || targetWeight <= 0)) {
      setState(() => _stepError = 'Le poids visé doit être un nombre positif.');
      return;
    }
    if (_birthDate == null || height == null || weight == null) {
      // Ne devrait pas arriver (déjà validé à l'étape 1), filet de sécurité.
      await _goToStep(0);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _stepError = null;
    });

    try {
      await ref
          .read(profileControllerProvider.notifier)
          .create(
            sex: _sex,
            birthDate: _birthDate!,
            heightCm: height,
            weightKg: weight,
            activityLevel: _activityLevel,
            targetWeightKg: targetWeight,
            weeklyWeightLossGoalKg: _customPace
                ? _weeklyWeightLossGoalKg
                : null,
          );
      if (!mounted) return;
      // Petit temps mort avec coche de succès avant de revenir à l'Accueil
      // (déjà prêt à afficher le dashboard, le profil vient d'être créé) —
      // un retour instantané donnait l'impression que rien ne s'était passé.
      setState(() {
        _isSubmitting = false;
        _isDone = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _stepError = '$e';
      });
    }
  }

  String _guidance() {
    switch (_step) {
      case 0:
        return 'Ces infos servent à calculer ton métabolisme de base.';
      case 1:
        return switch (_activityLevel) {
          ActivityLevel.sedentary || ActivityLevel.light => 'Peu de dépense physique : on resserre un peu plus l\'objectif calorique.',
          ActivityLevel.moderate =>
            'Un rythme équilibré, le plus courant au quotidien.',
          ActivityLevel.active || ActivityLevel.veryActive => 'Beaucoup de dépense physique : ton objectif calorique sera plus large.',
        };
      default:
        if (!_customPace) {
          return 'Déficit automatique de 20% sous ton métabolisme d\'entretien — simple et sans réflexion à avoir.';
        }
        if (_weeklyWeightLossGoalKg <= 0.4) {
          return 'Rythme doux : perte lente mais plus confortable à tenir dans la durée.';
        }
        if (_weeklyWeightLossGoalKg <= 0.75) {
          return 'Rythme modéré : bon compromis entre vitesse et confort.';
        }
        return 'Rythme soutenu : résultats plus rapides, demande plus de rigueur.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure ton profil',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: List.generate(_stepCount, (i) {
                      final active = i <= _step;
                      return Expanded(
                        child: Container(
                          height: 6,
                          margin: EdgeInsets.only(
                            right: i == _stepCount - 1 ? 0 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.brand
                                : AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _guidance(),
                      key: ValueKey(
                        '$_step-${_activityLevel.name}-$_customPace-$_weeklyWeightLossGoalKg',
                      ),
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
                  _StepScroll(
                    child: ProfileBasicsCard(
                      sex: _sex,
                      onSexChanged: (value) => setState(() => _sex = value),
                      birthDate: _birthDate,
                      onPickBirthDate: _pickBirthDate,
                      heightController: _heightController,
                      weightController: _weightController,
                    ),
                  ),
                  _StepScroll(
                    child: ActivityLevelCard(
                      activityLevel: _activityLevel,
                      onChanged: (value) =>
                          setState(() => _activityLevel = value),
                    ),
                  ),
                  _StepScroll(
                    child: GoalCard(
                      targetWeightController: _targetWeightController,
                      customPace: _customPace,
                      onCustomPaceChanged: (value) =>
                          setState(() => _customPace = value),
                      weeklyGoal: _weeklyWeightLossGoalKg,
                      onWeeklyGoalChanged: (value) =>
                          setState(() => _weeklyWeightLossGoalKg = value),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  if (_stepError != null) ...[
                    _ErrorLine(message: _stepError!),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      if (_step > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _goToStep(_step - 1),
                            child: const Text('Précédent'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: _step > 0 ? 2 : 1,
                        child: FilledButton(
                          onPressed: _isSubmitting
                              ? null
                              : (_step == _stepCount - 1 ? _finish : _next),
                          child: _isDone
                              ? const Icon(Icons.check_rounded)
                              : SubmitButtonContent(
                                  isSubmitting: _isSubmitting,
                                  label: Text(
                                    _step == _stepCount - 1
                                        ? 'Terminé'
                                        : 'Suivant',
                                  ),
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

/// Chaque étape défile indépendamment (clavier, champ "Poids visé" en bas de
/// l'étape 3...) sans perturber la pagination horizontale du `PageView`
/// parent.
class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: child,
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.errorText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
