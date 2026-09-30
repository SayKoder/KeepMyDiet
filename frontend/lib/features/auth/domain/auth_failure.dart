/// Erreur d'auth avec un message déjà prêt pour l'UI (voir `extractErrorMessage`).
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
