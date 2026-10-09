import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
import '../features/auth/presentation/auth_controller.dart';
import 'token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));
  final tokenStorage = ref.watch(tokenStorageProvider);

  // Injecte le JWT sur CHAQUE requête sortante (login/register n'en ont pas
  // besoin mais l'ignorent simplement côté serveur). Centralisé ici plutôt
  // que répété dans chaque *ApiClient de feature.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      // Le JWT expire au bout de 24h (voir token_ttl côté backend) ou peut
      // devenir invalide (déconnexion ailleurs, secret changé...) — sans ce
      // handler, ça se traduisait juste par des 401 affichés au
      // compte-gouttes écran par écran, en laissant l'utilisateur coincé sur
      // une session morte. Dès le premier 401, on vide la session globale :
      // `_AuthGate` (main.dart) réagit aussitôt et renvoie proprement sur
      // l'écran de connexion — le même chemin qu'une déconnexion manuelle
      // depuis le menu Profil. Un 401 de tentative de connexion ratée
      // (mauvais mot de passe) passe par ici aussi mais ne fait rien de plus
      // qu'un `logout()` sans session à couper (pas de token stocké).
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          ref.read(authControllerProvider.notifier).logout();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

/// Message lisible extrait d'une erreur API : API Platform renvoie `detail`
/// (ex: erreurs de validation), le firewall json_login de Symfony renvoie
/// `message` (ex: "Invalid credentials.") — on gère les deux formats.
String extractErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final detail = data['detail'] ?? data['message'];
    if (detail is String) {
      return detail;
    }
  }
  return "Une erreur est survenue, réessaie.";
}

/// Affiche `extractErrorMessage(error)` dans un SnackBar — le
/// `on DioException catch (e) { if (context.mounted) { ... } }` recopié
/// derrière la quasi-totalité des appels API déclenchés depuis un bouton.
void showErrorSnackBar(BuildContext context, DioException error) {
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(extractErrorMessage(error))));
  }
}
