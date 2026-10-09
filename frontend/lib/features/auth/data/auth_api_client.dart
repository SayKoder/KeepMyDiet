import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(ref.watch(dioProvider));
});

class AuthApiClient {
  AuthApiClient(this._dio);

  final Dio _dio;

  /// POST /api/login (json_login de Symfony Security, pas une ressource API
  /// Platform) — attend du JSON classique, renvoie {"token": "..."}.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/login',
      data: {'email': email, 'password': password},
      options: Options(contentType: 'application/json'),
    );

    return response.data!['token'] as String;
  }

  /// POST /api/users (ressource API Platform) — exige application/ld+json,
  /// sinon 415. `plainPassword` est le nom du champ côté entité Symfony.
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/users',
      data: {'email': email, 'plainPassword': password},
      options: Options(contentType: 'application/ld+json'),
    );
  }
}
