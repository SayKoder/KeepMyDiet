import 'package:flutter/material.dart';

import 'package:keepmydiet/core/theme.dart';

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
