import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';

import '../../../shared/round_back_button.dart';
import '../../../shared/submit_button_content.dart';
import '../../../shared/white_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/activity_level.dart';
import '../domain/profile.dart';
import '../domain/sex.dart';
import 'profile_controller.dart';

/// Réutilisé pour la création ET la modification : si `existingProfile` est
/// fourni, les champs sont pré-remplis et la soumission appelle `update` au
/// lieu de `create` — un seul écran, pas de duplication entre les deux cas.
class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key, this.existingProfile});

  final Profile? existingProfile;

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  late final _heightController = TextEditingController(
    text: widget.existingProfile?.heightCm.toString() ?? '',
  );
  late final _weightController = TextEditingController(
    text: widget.existingProfile?.weightKg.toString() ?? '',
  );
  late final _targetWeightController = TextEditingController(
    text: widget.existingProfile?.targetWeightKg?.toString() ?? '',
  );
  late Sex _sex = widget.existingProfile?.sex ?? Sex.male;
  late DateTime? _birthDate = widget.existingProfile?.birthDate;
  late ActivityLevel _activityLevel =
      widget.existingProfile?.activityLevel ?? ActivityLevel.moderate;
  late bool _customPace =
      widget.existingProfile?.weeklyWeightLossGoalKg != null;
  late double _weeklyWeightLossGoalKg =
      widget.existingProfile?.weeklyWeightLossGoalKg ?? 0.5;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
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

  Future<void> _submit() async {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final targetWeightText = _targetWeightController.text.trim();
    final targetWeight = targetWeightText.isEmpty
        ? null
        : double.tryParse(targetWeightText);

    if (_birthDate == null) {
      setState(() => _errorMessage = 'Choisis ta date de naissance.');
      return;
    }
    if (height == null || height <= 0 || weight == null || weight <= 0) {
      setState(
        () => _errorMessage =
            'Taille et poids doivent être des nombres positifs.',
      );
      return;
    }
    if (targetWeightText.isNotEmpty &&
        (targetWeight == null || targetWeight <= 0)) {
      setState(
        () => _errorMessage = 'Le poids visé doit être un nombre positif.',
      );
      return;
    }

    final weeklyGoal = _customPace ? _weeklyWeightLossGoalKg : null;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(profileControllerProvider.notifier);
      if (widget.existingProfile == null) {
        await controller.create(
          sex: _sex,
          birthDate: _birthDate!,
          heightCm: height,
          weightKg: weight,
          activityLevel: _activityLevel,
          targetWeightKg: targetWeight,
          weeklyWeightLossGoalKg: weeklyGoal,
        );
      } else {
        await controller.updateProfile(
          sex: _sex,
          birthDate: _birthDate!,
          heightCm: height,
          weightKg: weight,
          activityLevel: _activityLevel,
          targetWeightKg: targetWeight,
          weeklyWeightLossGoalKg: weeklyGoal,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Tu devras te reconnecter avec ton email et ton mot de passe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                const RoundBackButton(),
                const SizedBox(width: 12),
                Text(
                  widget.existingProfile == null
                      ? 'Créer mon profil'
                      : 'Modifier mon profil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            WhiteCard(
              radius: AppRadius.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: Sex.values.map((sex) {
                        final selected = _sex == sex;
                        return Expanded(
                          child: Material(
                            color: selected
                                ? AppColors.ink
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              onTap: () => setState(() => _sex = sex),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                child: Text(
                                  sex.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickBirthDate,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Date de naissance',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _birthDate == null
                                    ? 'Non renseignée'
                                    : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: AppColors.brand,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniNumberField(
                          label: 'Taille',
                          unit: 'cm',
                          controller: _heightController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniNumberField(
                          label: 'Poids',
                          unit: 'kg',
                          controller: _weightController,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            WhiteCard(
              radius: AppRadius.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "NIVEAU D'ACTIVITÉ",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ActivityLevel.values.map((level) {
                      final selected = _activityLevel == level;
                      return Material(
                        color: selected ? AppColors.brandLight : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: () => setState(() => _activityLevel = level),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selected
                                    ? AppColors.brand
                                    : AppColors.border,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              level.shortLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppColors.brandDark
                                    : const Color(0xFF3E4A43),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            WhiteCard(
              radius: AppRadius.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OBJECTIF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MiniNumberField(
                    label: 'Poids visé — optionnel',
                    unit: 'kg',
                    controller: _targetWeightController,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Sert uniquement à estimer le délai, n'influence pas l'objectif calorique.",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rythme de perte personnalisé',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Sinon : déficit fixe de 20% du maintien.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _customPace,
                        onChanged: (value) =>
                            setState(() => _customPace = value),
                      ),
                    ],
                  ),
                  if (_customPace) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${_weeklyWeightLossGoalKg.toStringAsFixed(2)} kg / semaine',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Slider(
                      value: _weeklyWeightLossGoalKg,
                      min: 0.25,
                      max: 1,
                      divisions: 3,
                      label: '${_weeklyWeightLossGoalKg.toStringAsFixed(2)} kg',
                      onChanged: (value) =>
                          setState(() => _weeklyWeightLossGoalKg = value),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '0.25',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '0.50',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '0.75',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '1.00',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _Banner(
                      message: "L'objectif ne descendra jamais sous ton métabolisme de base (plancher de sécurité).",
                      icon: Icons.info_outline,
                      background: AppColors.brandLight,
                      foreground: AppColors.brandDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Banner(
                  message: _errorMessage!,
                  icon: Icons.error_outline,
                  background: AppColors.errorBg,
                  foreground: AppColors.errorText,
                ),
              ),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _confirmLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorText,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: SubmitButtonContent(
                isSubmitting: _isSubmitting,
                label: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniNumberField extends StatelessWidget {
  const _MiniNumberField({
    required this.label,
    required this.unit,
    required this.controller,
  });

  final String label;
  final String unit;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 70,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                  decoration: const InputDecoration(
                    // Annule le style "rempli" global du thème (`theme.dart`
                    // met `filled: true` sur TOUS les champs) : ici le champ
                    // vit déjà dans un Container teinté, un 2e fond grisé
                    // par-dessus aurait fait un rectangle dans le rectangle.
                    filled: false,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
