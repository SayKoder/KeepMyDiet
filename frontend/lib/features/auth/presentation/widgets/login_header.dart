import 'package:flutter/material.dart';

import '../../../../core/theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -40,
            child: _Circle(
              size: 220,
              border: Border.all(
                color: AppColors.limeAccent.withValues(alpha: 0.16),
                width: 28,
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: 120,
            child: _Circle(
              size: 70,
              color: AppColors.limeAccent.withValues(alpha: 0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'KeepMyDiet',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tes calories, ton frigo et tes courses, au même endroit.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, this.color, this.border});

  final double size;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: border,
      ),
    );
  }
}
