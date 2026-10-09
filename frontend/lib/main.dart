import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'features/auth/domain/auth_session.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_shell.dart';
import 'shared/responsive.dart';

/// Permet à `_AuthGate` de vider la pile de navigation depuis son `ref.listen`
/// (voir plus bas) sans dépendre d'un `BuildContext` d'écran particulier —
/// utile aussi bien pour la déconnexion manuelle (bouton dans Profil, lui-même
/// ouvert via `Navigator.push`) que pour la déconnexion auto sur 401.
final navigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: navigatorKey,
      title: 'KeepMyDiet',
      theme: AppTheme.light(),
      // Toute l'app est pensée mobile-first (tailles, paddings fixes repris
      // de la maquette téléphone). Plutôt que de réadapter chaque écran un
      // par un pour tablette/desktop/web, on recentre ce même layout dans
      // une colonne de largeur raisonnable (`ResponsiveCenter`, déjà fait
      // pour ça) dès que l'écran est plus large — sur téléphone (< 720dp)
      // `ConstrainedBox` ne change rien, donc zéro régression ici.
      builder: (context, child) => ResponsiveCenter(child: child!),
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
    // `ProfileFormScreen` (seul accès au bouton "Se déconnecter") est ouvert
    // via `Navigator.push` PAR-DESSUS cette route racine — sans ce `listen`,
    // quand la session passe à `null` (déconnexion manuelle ou auto sur 401),
    // ce widget bascule bien en interne vers `LoginScreen`, mais la route
    // poussée reste affichée devant, cachant tout : l'utilisateur reste
    // visuellement bloqué sur l'écran qu'il vient de quitter. On vide la pile
    // jusqu'à la racine dès que la session se ferme pour que `LoginScreen`
    // redevienne réellement visible.
    ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (
      previous,
      next,
    ) {
      final wasLoggedIn = previous?.value != null;
      final isNowLoggedOut = !next.isLoading && next.value == null;
      if (wasLoggedIn && isNowLoggedOut) {
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });

    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (session) =>
          session == null ? const LoginScreen() : const HomeShell(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Erreur de démarrage : $error'))),
    );
  }
}
