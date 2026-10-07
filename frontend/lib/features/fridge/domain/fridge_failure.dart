/// Erreur frigo avec un message déjà prêt pour l'UI (voir `extractErrorMessage`).
class FridgeFailure implements Exception {
  const FridgeFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
