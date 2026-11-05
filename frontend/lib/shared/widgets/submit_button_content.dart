import 'package:flutter/material.dart';

class SubmitButtonContent extends StatelessWidget {
  const SubmitButtonContent({
    super.key,
    required this.isSubmitting,
    required this.label,
    this.size = 20,
  });

  final bool isSubmitting;
  final Widget label;

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
