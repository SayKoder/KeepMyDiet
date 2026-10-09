import 'package:flutter/material.dart';

/// Contenu d'un bouton de soumission : le libellé normalement, un petit
/// spinner à sa place pendant l'envoi — recopié à l'identique (`_isSubmitting
/// ? SizedBox(...CircularProgressIndicator...) : Text(...)`) dans la
/// quasi-totalité des formulaires de l'appli.
class SubmitButtonContent extends StatelessWidget {
  const SubmitButtonContent({
    super.key,
    required this.isSubmitting,
    required this.label,
    this.size = 20,
  });

  final bool isSubmitting;
  final Widget label;

  /// Taille du spinner — 20 par défaut (bouton pleine largeur), 16 dans les
  /// boutons plus compacts d'une boîte de dialogue.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!isSubmitting) {
      return label;
    }
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
