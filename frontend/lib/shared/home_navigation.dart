import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet actif de la bottom nav (`HomeShell`). Dans un provider partagé
/// (plutôt que l'état interne de `HomeShell`) car d'autres écrans doivent
/// pouvoir changer d'onglet par eux-même (ex: taper un groupe dans "Groupes"
/// doit basculer vers "Frigo").
///
/// `riverpod` 3 n'a plus `StateProvider` dans les exports par défaut — ce
/// `Notifier` minimal est l'équivalent moderne. Contrairement à `StateProvider`,
/// `state` n'est pas assignable depuis l'extérieur (protégé par riverpod),
/// d'où la petite méthode `show()`.
class HomeTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void show(int index) => state = index;
}

final homeTabIndexProvider = NotifierProvider<HomeTabIndexNotifier, int>(
  HomeTabIndexNotifier.new,
);
