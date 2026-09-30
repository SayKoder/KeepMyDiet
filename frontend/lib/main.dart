import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/groups/presentation/groups_list_screen.dart';

void main() {
  // ProviderScope doit envelopper toute l'app : c'est lui qui porte l'état de
  // tous les providers Riverpod (dioProvider, authControllerProvider, ...).
  runApp(const ProviderScope(child: KeepMyDietApp()));
}

class KeepMyDietApp extends StatelessWidget {
  const KeepMyDietApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeepMyDiet',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const _AuthGate(),
    );
  }
}

/// Écoute la session d'auth et affiche l'écran adapté — c'est ici que
/// `ref.watch(authControllerProvider)` remplace le "prop drilling" : ni
/// `MaterialApp`, ni `KeepMyDietApp` n'ont eu besoin de connaître la session.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (session) => session == null ? const LoginScreen() : const GroupsListScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Erreur de démarrage : $error')),
      ),
    );
  }
}
