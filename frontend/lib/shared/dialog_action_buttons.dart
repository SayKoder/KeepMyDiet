import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Deux boutons d'action de popup de confirmation, toujours côte à côte —
/// contrairement à `actions:` passé directement à `AlertDialog` (son
/// `OverflowBar` interne empile les boutons à la verticale dès que leur
/// texte ne tient pas sur une seule ligne à la largeur du dialog). Le
/// secondaire est un `OutlinedButton` avec un contour `AppColors.border`
/// (toujours visible sur le fond blanc d'un dialog, pas juste du texte qui
/// se fond dedans), le principal un `FilledButton` classique.
class DialogActionButtons extends StatelessWidget {
  const DialogActionButtons({
    super.key,
    required this.cancelLabel,
    required this.onCancel,
    required this.confirmLabel,
    required this.onConfirm,
    this.confirmChild,
  });

  final String cancelLabel;
  final VoidCallback? onCancel;
  final String confirmLabel;
  final VoidCallback? onConfirm;

  /// Remplace `Text(confirmLabel)` quand le bouton principal doit afficher
  /// autre chose qu'un simple libellé (ex: un spinner de soumission via
  /// `SubmitButtonContent`).
  final Widget? confirmChild;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
            ),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onConfirm,
            child: confirmChild ?? Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
