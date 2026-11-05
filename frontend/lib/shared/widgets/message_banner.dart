import 'package:flutter/material.dart';

import 'package:keepmydiet/core/theme.dart';

class MessageBanner extends StatelessWidget {
  const MessageBanner.error({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
  }) : background = AppColors.errorBg,
       foreground = AppColors.errorText;

  const MessageBanner.info({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  }) : background = AppColors.brandLight,
       foreground = AppColors.brandDark,
       onRetry = null;

  final String message;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: background,
      textColor: foreground,
      iconColor: foreground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      leading: Icon(icon, size: 18),
      title: Text(
        message,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      trailing: onRetry == null
          ? null
          : TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: const Text('Réessayer'),
            ),
    );
  }
}
