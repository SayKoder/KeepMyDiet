import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/message_banner.dart';
import '../../../shared/widgets/segmented_pill.dart';
import 'auth_controller.dart';
import 'widgets/login_header.dart';

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
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(bool isRegisterMode) => setState(() {
    _isRegisterMode = isRegisterMode;
    _errorMessage = null;
  });

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = ref.read(authControllerProvider.notifier);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await auth.register(email: email, password: password);
      } else {
        await auth.login(email: email, password: password);
      }
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    // L'en-tête est dans la zone scrollable pour laisser la place au clavier.
    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
            const LoginHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  SegmentedPill<bool>(
                    values: const [false, true],
                    selected: _isRegisterMode,
                    labelOf: (register) =>
                        register ? 'Créer un compte' : 'Connexion',
                    onChanged: _isSubmitting ? null : _switchMode,
                  ),
                  const SizedBox(height: 12),
                  Text('Email', style: labelStyle),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Mot de passe', style: labelStyle),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    MessageBanner.error(message: _errorMessage!),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      _isRegisterMode ? 'Créer mon compte' : 'Se connecter',
                    ),
                  ),
                  if (!_isRegisterMode)
                    const TextButton(
                      onPressed: null,
                      child: Text('Mot de passe oublié ?'),
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
