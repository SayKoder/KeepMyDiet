import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
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
