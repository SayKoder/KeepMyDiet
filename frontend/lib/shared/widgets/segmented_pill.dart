import 'package:flutter/material.dart';

import '../../core/theme.dart';

class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.badgeOf,
    this.selectedColor = Colors.white,
    this.selectedTextColor = AppColors.ink,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T>? onChanged;
  final String Function(T value)? badgeOf;
  final Color selectedColor;
  final Color selectedTextColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: AppColors.border.withValues(alpha: 0.6),
        shape: const StadiumBorder(),
      ),
      child: Row(
        children: [
          for (final value in values)
            Expanded(
              child: _Segment(
                label: labelOf(value),
                badge: badgeOf?.call(value),
                selected: value == selected,
                selectedColor: selectedColor,
                selectedTextColor: selectedTextColor,
                onTap: onChanged == null ? null : () => onChanged!(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.badge,
    required this.selected,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.onTap,
  });

  final String label;
  final String? badge;
  final bool selected;
  final Color selectedColor;
  final Color selectedTextColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? selectedTextColor : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: ShapeDecoration(
          color: selected ? selectedColor : Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            if (badge != null)
              Badge(
                label: Text(badge!),
                backgroundColor: selected ? AppColors.brandLight : Colors.white,
                textColor: selected
                    ? AppColors.brandDark
                    : AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
          ],
        ),
      ),
    );
  }
}
