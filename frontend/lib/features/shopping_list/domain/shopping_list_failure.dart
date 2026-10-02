/// Erreur liste de courses avec un message déjà prêt pour l'UI (voir `extractErrorMessage`).
class ShoppingListFailure implements Exception {
  const ShoppingListFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
