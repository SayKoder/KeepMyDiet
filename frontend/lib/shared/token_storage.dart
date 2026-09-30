import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

/// Coffre-fort chiffré (Keystore Android / Keychain iOS) pour le JWT — jamais
/// dans les SharedPreferences ou le localStorage, qui ne sont pas chiffrés.
///
/// Vit dans `shared/` (et pas dans `features/auth/data/`) car `api_client.dart`
/// en a besoin pour injecter le token sur toutes les requêtes authentifiées,
/// pas seulement celles de la feature auth.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'jwt_token';

  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> write(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> delete() => _storage.delete(key: _tokenKey);
}
