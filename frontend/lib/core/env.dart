/// Config d'environnement — pour l'instant en dur, à revoir (ex: --dart-define)
/// quand on aura un vrai serveur de dev distinct par plateforme.
class Env {
  Env._();

  /// 10.0.2.2 = alias fourni par l'émulateur Android pour désigner la machine
  /// hôte (127.0.0.1 depuis l'émulateur pointerait vers l'émulateur lui-même).
  ///
  /// TEMPORAIRE : basculé sur 127.0.0.1 pour tester sur téléphone physique
  /// via `adb reverse tcp:8000 tcp:8000` (redirige le localhost du téléphone
  /// vers celui du PC). À remettre sur 10.0.2.2 pour retester sur émulateur —
  /// ce sera à rendre configurable par plateforme plus tard (--dart-define).
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api';
}
