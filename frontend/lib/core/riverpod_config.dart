/// Riverpod 3 relance par défaut 10 fois un provider en échec, avec un délai
/// croissant : hors-ligne, l'écran d'erreur n'apparaissait qu'après ~40 s de
/// chargement. Chaque écran a déjà son bouton « Réessayer », on coupe donc la
/// relance automatique.
Duration? noAutoRetry(int retryCount, Object error) => null;
