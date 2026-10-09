import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Carte "blanche à bordure" utilisée dans tous les écrans construits dans le
/// style de la maquette (Accueil, Profil, Groupes...) — même trio
/// couleur/bordure/radius recopié à chaque fois, seuls le padding et le
/// radius varient d'un endroit à l'autre.
class WhiteCard extends StatelessWidget {
  const WhiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppRadius.lg,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
