/// Erreur groupe avec un message déjà prêt pour l'UI (voir `extractErrorMessage`).
class GroupFailure implements Exception {
  const GroupFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
