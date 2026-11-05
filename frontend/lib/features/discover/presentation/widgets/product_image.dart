import 'package:flutter/material.dart';
import 'package:keepmydiet/core/theme.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.cacheWidth = 400});

  final String? url;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.fieldFill,
      child: Center(
        child: Icon(Icons.fastfood_outlined, color: AppColors.iconMuted),
      ),
    );
    final imageUrl = url;
    if (imageUrl == null) return placeholder;

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}
