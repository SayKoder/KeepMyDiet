import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rendu par défaut (spinner centré / "Erreur : ..." centré) d'un
/// [AsyncValue] consommé pour construire une UI — recopié à l'identique dans
/// la quasi-totalité des écrans qui lisent un provider Riverpod ; ce helper
/// réduit chaque appel à son seul cas `data`, propre à l'écran.
extension AsyncValueUi<T> on AsyncValue<T> {
  Widget toWidget({required Widget Function(T data) data}) {
    return when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erreur : $error')),
    );
  }
}
