import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/auth/data/auth_api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authApiClientProvider));
});

class AuthRepository {
  AuthRepository(this._api);

  final AuthApiClient _api;

  Future<String> login({required String email, required String password}) =>
      _api.login(email: email, password: password);

  Future<void> register({required String email, required String password}) =>
      _api.register(email: email, password: password);
}
