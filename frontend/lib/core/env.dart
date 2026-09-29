/// Config d'environnement — pour l'instant en dur, à revoir (ex: --dart-define)
/// quand on aura un vrai serveur de dev distinct par plateforme.
class Env {
  Env._();

  /// 10.0.2.2 = alias fourni par l'émulateur Android pour désigner la machine
  /// hôte (127.0.0.1 depuis l'émulateur pointerait vers l'émulateur lui-même).
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api';
}
