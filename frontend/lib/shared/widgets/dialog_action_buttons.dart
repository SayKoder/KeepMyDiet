import 'package:flutter/material.dart';

import '../../core/theme.dart';

// Toujours côte à côte : les `actions` d'un AlertDialog s'empilent si le
// texte est trop long.
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
