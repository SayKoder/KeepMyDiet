import 'package:flutter/material.dart';

class LetterAvatar extends StatelessWidget {
  const LetterAvatar({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.size = 44,
    this.radius = 12,
    this.circle = false,
    this.border,
  });

  final String text;
  final Color background;
  final Color foreground;
  final double size;
  final double radius;
  final bool circle;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
        border: border,
      ),
      child: Text(
        text.isEmpty ? '?' : text[0].toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
