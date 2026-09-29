import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

/// `ConsumerStatefulWidget` = un `StatefulWidget` classique (on a besoin d'un
/// état local : les champs du formulaire, le mode login/register, et l'état
/// "soumission en cours" propre à CET écran) qui a aussi accès à `ref` pour
/// lire/observer les providers Riverpod.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final controller = ref.read(authControllerProvider.notifier);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await controller.register(email: email, password: password);
      } else {
        await controller.login(email: email, password: password);
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
      appBar: AppBar(title: const Text('KeepMyDiet')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isRegisterMode ? 'Créer un compte' : 'Connexion',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
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
                    : Text(_isRegisterMode ? 'Créer mon compte' : 'Se connecter'),
              ),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _errorMessage = null;
                      }),
                child: Text(
                  _isRegisterMode ? "J'ai déjà un compte" : "Créer un compte",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
