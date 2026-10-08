import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_shell.dart';

void main() async {
  // Nécessaire avant tout `DateFormat(pattern, 'fr_FR')` (planning de repas) —
  // sans ça, `intl` lève une exception "Locale data has not been
  // initialized" au premier formatage de date.
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

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
      // Sans ça, les widgets Material (dont le sélecteur de date en mode
      // saisie clavier) retombent sur un format par défaut sans séparateurs
      // automatiques ("jj/mm/aaaa" devient juste une suite de chiffres) : le
      // bug remonté par Carl ("24052004" illisible) vient de là, pas d'un
      // champ de saisie custom.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      locale: const Locale('fr', 'FR'),
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
      data: (session) => session == null ? const LoginScreen() : const HomeShell(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Erreur de démarrage : $error')),
      ),
    );
  }
}
