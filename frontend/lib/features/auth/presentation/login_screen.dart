import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';

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
  bool _obscurePassword = true;

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
      backgroundColor: AppColors.background,
      // `_Header()` était un sibling FIXE de la zone scrollable (hors
      // `SingleChildScrollView`) : il gardait toute sa hauteur même quand le
      // clavier apparaissait, ne laissant quasi plus de place pour voir le
      // champ en cours de saisie en dessous. En le mettant DANS le
      // scrollable, il peut défiler hors écran comme le reste quand le
      // clavier pousse le contenu, et `Scrollable.ensureVisible` (déclenché
      // automatiquement au focus d'un `TextField`) peut vraiment amener le
      // champ actif au-dessus du clavier.
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ModeSwitch(
                      isRegisterMode: _isRegisterMode,
                      onChanged: _isSubmitting
                          ? null
                          : (value) => setState(() {
                              _isRegisterMode = value;
                              _errorMessage = null;
                            }),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Email',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mot de passe',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
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
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _errorMessage!),
                    ],
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
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
                      TextButton(
                        onPressed: null,
                        child: const Text('Mot de passe oublié ?'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        // Pas de padding ici : le Stack doit occuper TOUTE la boîte verte
        // (bords compris), exactement comme la div CSS dont les cercles sont
        // positionnés en absolu — sinon `Positioned(right: -60, ...)` se
        // calcule par rapport à une boîte déjà réduite par le padding, pas
        // par rapport au vrai bord du bandeau.
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -60,
            top: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.limeAccent.withValues(alpha: 0.16),
                  width: 28,
                ),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: 120,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.limeAccent.withValues(alpha: 0.14),
              ),
            ),
          ),
          // Le padding du texte est ICI, sur son propre widget — le Stack
          // autour de lui reste à la taille complète du bandeau.
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'KeepMyDiet',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tes calories, ton frigo et tes courses, au même endroit.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.isRegisterMode, required this.onChanged});

  final bool isRegisterMode;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'Connexion',
              selected: !isRegisterMode,
              onTap: onChanged == null ? null : () => onChanged!(false),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Créer un compte',
              selected: isRegisterMode,
              onTap: onChanged == null ? null : () => onChanged!(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      elevation: selected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppColors.ink : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.errorText,
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
