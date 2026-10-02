/// Erreur profil avec un message déjà prêt pour l'UI (voir `extractErrorMessage`).
class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
