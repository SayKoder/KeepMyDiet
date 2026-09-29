import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: Env.apiBaseUrl));
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
