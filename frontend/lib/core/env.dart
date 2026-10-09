/// Config d'environnement — l'URL de l'API se surcharge au build via
/// `--dart-define=API_BASE_URL=...` (utilisé par le build web, cf. Dockerfile).
class Env {
  Env._();

  /// 10.0.2.2 = alias fourni par l'émulateur Android pour désigner la machine
  /// hôte (127.0.0.1 depuis l'émulateur pointerait vers l'émulateur lui-même).
  ///
  /// TEMPORAIRE : basculé sur 127.0.0.1 pour tester sur téléphone physique
  /// via `adb reverse tcp:8000 tcp:8000` (redirige le localhost du téléphone
  /// vers celui du PC). À remettre sur 10.0.2.2 pour retester sur émulateur —
  /// ce sera à rendre configurable par plateforme plus tard (--dart-define).
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  /// Un chemin relatif (ex: `/keepmydiet/api`) n'a de sens qu'en web : on le
  /// résout sur l'origine de la page pour appeler l'API en même origine.
  static String get apiBaseUrl => _apiBaseUrl.startsWith('/')
      ? '${Uri.base.origin}$_apiBaseUrl'
      : _apiBaseUrl;
}
