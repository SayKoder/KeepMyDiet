import 'package:flutter/material.dart';

enum ScreenSize {
  compact, // < 600 dp : téléphone portrait
  medium, // 600–839 dp : téléphone paysage, petite tablette
  expanded; // ≥ 840 dp : tablette

  static ScreenSize fromWidth(double width) {
    if (width >= 840) return expanded;
    if (width >= 600) return medium;
    return compact;
  }
}

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ScreenSize size) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          builder(context, ScreenSize.fromWidth(constraints.maxWidth)),
    );
  }
}

class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
