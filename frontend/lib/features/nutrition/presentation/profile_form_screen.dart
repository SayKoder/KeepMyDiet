import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  late Sex _sex = widget.existingProfile?.sex ?? Sex.male;
  late DateTime? _birthDate = widget.existingProfile?.birthDate;
  late ActivityLevel _activityLevel = widget.existingProfile?.activityLevel ?? ActivityLevel.moderate;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
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

    if (_birthDate == null) {
      setState(() => _errorMessage = 'Choisis ta date de naissance.');
      return;
    }
    if (height == null || height <= 0 || weight == null || weight <= 0) {
      setState(() => _errorMessage = 'Taille et poids doivent être des nombres positifs.');
      return;
    }

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
        );
      } else {
        await controller.updateProfile(
          sex: _sex,
          birthDate: _birthDate!,
          heightCm: height,
          weightKg: weight,
          activityLevel: _activityLevel,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProfile == null ? 'Créer mon profil' : 'Modifier mon profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SegmentedButton<Sex>(
            segments: Sex.values
                .map((sex) => ButtonSegment(value: sex, label: Text(sex.label)))
                .toList(),
            selected: {_sex},
            onSelectionChanged: (selection) => setState(() => _sex = selection.first),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date de naissance'),
            subtitle: Text(
              _birthDate == null
                  ? 'Non renseignée'
                  : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickBirthDate,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Taille (cm)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Poids (kg)'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ActivityLevel>(
            initialValue: _activityLevel,
            decoration: const InputDecoration(labelText: "Niveau d'activité"),
            items: ActivityLevel.values
                .map((level) => DropdownMenuItem(value: level, child: Text(level.label)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _activityLevel = value);
              }
            },
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
