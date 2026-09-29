import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../data/auth_api_client.dart';
import '../data/token_storage.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_session.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

/// Session d'authentification, accessible depuis n'importe quel widget via
/// `ref.watch(authControllerProvider)`. `AsyncNotifier` encapsule l'état dans
/// un `AsyncValue` (loading / data / error) — pratique ici car `build()` doit
/// lire le stockage sécurisé de façon asynchrone avant de savoir si on a déjà
/// une session valide (reconnexion automatique au démarrage de l'app).
class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final token = await ref.watch(tokenStorageProvider).read();

    return token == null ? null : AuthSession(token: token);
  }

  /// Ne touche à `state` qu'en cas de succès — l'état "en cours"/"erreur" de
  /// CETTE tentative est un problème local à l'écran de login (voir
  /// `LoginScreen._isSubmitting`), pas une information sur la session globale.
  /// Si on mettait `state = AsyncLoading()` ici, `_AuthGate` (qui observe la
  /// même session partout dans l'app) remplacerait tout l'écran par un
  /// spinner plein écran à chaque tentative de connexion, alors qu'on veut
  /// juste un spinner sur le bouton.
  Future<void> login({required String email, required String password}) async {
    state = AsyncData(await _loginAndPersist(email, password));
  }

  Future<void> register({required String email, required String password}) async {
    try {
      await ref.read(authApiClientProvider).register(email: email, password: password);
    } on DioException catch (e) {
      throw AuthFailure(extractErrorMessage(e));
    }
    state = AsyncData(await _loginAndPersist(email, password));
  }

  Future<AuthSession> _loginAndPersist(String email, String password) async {
    final String token;
    try {
      token = await ref.read(authApiClientProvider).login(email: email, password: password);
    } on DioException catch (e) {
      throw AuthFailure(extractErrorMessage(e));
    }
    await ref.read(tokenStorageProvider).write(token);

    return AuthSession(token: token);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).delete();
    state = const AsyncData(null);
  }
}
