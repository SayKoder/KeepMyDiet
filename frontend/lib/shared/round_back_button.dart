import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Bouton retour rond blanc utilisé en haut des écrans construits "pleine
/// page" (sans `AppBar` Material standard, juste une `Row` manuelle) —
/// dupliqué à l'identique sur plusieurs de ces écrans.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size(44, 44),
        shape: const CircleBorder(),
      ),
    );
  }
}
