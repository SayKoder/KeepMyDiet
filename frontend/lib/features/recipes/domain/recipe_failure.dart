/// Erreur recette avec un message déjà prêt pour l'UI (voir `extractErrorMessage`).
class RecipeFailure implements Exception {
  const RecipeFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
