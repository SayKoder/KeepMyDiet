import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../data/groups_api_client.dart';
import '../domain/group_failure.dart';
import 'groups_controller.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _tokenController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Colle le code reçu.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(groupsApiClientProvider).joinByToken(token);
      // Fait apparaître le nouveau groupe dans "Mes groupes" sans attendre
      // que l'utilisateur revienne manuellement rafraîchir la liste.
      await ref.read(groupsControllerProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      setState(() => _errorMessage = extractErrorMessage(e));
    } catch (e) {
      setState(() => _errorMessage = (e is GroupFailure) ? e.message : '$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rejoindre un groupe')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Colle le code d'invitation reçu de la personne qui t'invite."),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              autofocus: true,
              decoration: const InputDecoration(labelText: "Code d'invitation"),
              onSubmitted: (_) => _submit(),
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
                  : const Text('Rejoindre'),
            ),
          ],
        ),
      ),
    );
  }
}
