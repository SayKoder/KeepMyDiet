import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/message_banner.dart';
import '../../../shared/widgets/round_back_button.dart';
import '../../../shared/widgets/submit_button_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/activity_level.dart';
import '../domain/profile.dart';
import '../domain/sex.dart';
import 'profile_controller.dart';
import 'profile_input.dart';
import 'widgets/activity_level_card.dart';
import 'widgets/goal_card.dart';
import 'widgets/profile_basics_card.dart';

// Création si `existingProfile` est null, modification sinon.
class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key, this.existingProfile});

  final Profile? existingProfile;

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  late final Profile? _profile = widget.existingProfile;
  late final _heightController = TextEditingController(
    text: _profile?.heightCm.toString(),
  );
  late final _weightController = TextEditingController(
    text: _profile?.weightKg.toString(),
  );
  late final _targetWeightController = TextEditingController(
    text: _profile?.targetWeightKg?.toString(),
  );
  late Sex _sex = _profile?.sex ?? Sex.male;
  late DateTime? _birthDate = _profile?.birthDate;
  late ActivityLevel _activityLevel =
      _profile?.activityLevel ?? ActivityLevel.moderate;
  late bool _customPace = _profile?.weeklyWeightLossGoalKg != null;
  late double _weeklyGoal = _profile?.weeklyWeightLossGoalKg ?? 0.5;
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
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    final error =
        validateBasics(
          birthDate: _birthDate,
          height: _heightController.text,
          weight: _weightController.text,
        ) ??
        validateTargetWeight(_targetWeightController.text);

    setState(() {
      _errorMessage = error;
      _isSubmitting = error == null;
    });
    if (error != null) return;

    final profiles = ref.read(profileControllerProvider.notifier);
    final save = _profile == null ? profiles.create : profiles.updateProfile;

    try {
      await save(
        sex: _sex,
        birthDate: _birthDate!,
        heightCm: parsePositive(_heightController.text)!,
        weightKg: parsePositive(_weightController.text)!,
        activityLevel: _activityLevel,
        targetWeightKg: parsePositive(_targetWeightController.text),
        weeklyWeightLossGoalKg: _customPace ? _weeklyGoal : null,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              spacing: 12,
              children: [
                const RoundBackButton(),
                Text(
                  _profile == null ? 'Créer mon profil' : 'Modifier mon profil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ProfileBasicsCard(
              sex: _sex,
              onSexChanged: (value) => setState(() => _sex = value),
              birthDate: _birthDate,
              onPickBirthDate: _pickBirthDate,
              heightController: _heightController,
              weightController: _weightController,
            ),
            const SizedBox(height: 16),
            ActivityLevelCard(
              activityLevel: _activityLevel,
              onChanged: (value) => setState(() => _activityLevel = value),
            ),
            const SizedBox(height: 16),
            GoalCard(
              targetWeightController: _targetWeightController,
              customPace: _customPace,
              onCustomPaceChanged: (value) =>
                  setState(() => _customPace = value),
              weeklyGoal: _weeklyGoal,
              onWeeklyGoalChanged: (value) =>
                  setState(() => _weeklyGoal = value),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              MessageBanner.error(message: _errorMessage!),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _confirmLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorText,
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
