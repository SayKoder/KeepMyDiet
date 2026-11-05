import 'package:flutter/material.dart';

import '../../../../core/theme.dart';

class CheckoutBar extends StatelessWidget {
  const CheckoutBar({super.key, required this.count, required this.onValidate});

  final int count;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final plural = count > 1 ? 's' : '';

    return Material(
      color: AppColors.ink,
      elevation: 12,
      shadowColor: AppColors.ink.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(28),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(20, 6, 10, 6),
        title: Text(
          '$count article$plural coché$plural',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          'À ranger au frigo ou au placard',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        trailing: FilledButton(
          onPressed: onValidate,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.limeAccent,
            foregroundColor: AppColors.ink,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Valider'),
        ),
      ),
    );
  }
}
