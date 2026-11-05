import 'package:flutter/material.dart';

import 'package:keepmydiet/core/theme.dart';

// Coche plein écran affichée juste avant le rideau (même fond `hero`).
class OnboardingSuccessView extends StatelessWidget {
  const OnboardingSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hero,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: const CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.limeAccent,
            child: Icon(Icons.check_rounded, color: AppColors.hero, size: 44),
          ),
        ),
      ),
    );
  }
}

// Remplace l'écran courant par un rideau de 3 couches qui glissent vers le
// haut l'une après l'autre et dévoilent l'écran déjà présent en dessous.
void revealScreenBelow(BuildContext context) {
  final navigator = Navigator.of(context);
  final currentRoute = ModalRoute.of(context);

  navigator.push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const _RevealCurtain(),
    ),
  );
  if (currentRoute != null) navigator.removeRoute(currentRoute);
}

class _RevealCurtain extends StatefulWidget {
  const _RevealCurtain();

  @override
  State<_RevealCurtain> createState() => _RevealCurtainState();
}

class _RevealCurtainState extends State<_RevealCurtain>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _layer(double start, double end, Color color) {
    final progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeInOutCubic),
    );
    return SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: const Offset(0, -1.15),
      ).animate(progress),
      child: ColoredBox(color: color),
    );
  }

  // La dernière couche peinte (hero) est visible en premier et part d'abord.
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _layer(0.3, 0.85, AppColors.limeAccent),
        _layer(0.15, 0.7, AppColors.brand),
        _layer(0, 0.55, AppColors.hero),
      ],
    );
  }
}
