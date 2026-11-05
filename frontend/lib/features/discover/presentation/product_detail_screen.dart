import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/discover/presentation/discover_controller.dart';
import 'package:keepmydiet/features/discover/presentation/widgets/add_to_list_button.dart';
import 'package:keepmydiet/features/discover/presentation/widgets/nutri_score_pill.dart';
import 'package:keepmydiet/features/discover/presentation/widgets/product_image.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';
import 'package:keepmydiet/shared/responsive.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.product});

  final OpenFoodFactsProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = switch (product.barcode) {
      final barcode? => ref.watch(productDetailProvider(barcode)),
      null => null,
    };
    final detail = detailAsync?.value ?? product;
    final unavailable = _Unavailable(
      onRetry: () => ref.invalidate(productDetailProvider(product.barcode!)),
    );

    final info = _ProductInfo(
      product: detail,
      extras: detailAsync?.when(
        data: (loaded) =>
            loaded == null ? unavailable : _ProductExtras(product: loaded),
        loading: () =>
            const Padding(padding: EdgeInsets.all(24), child: LoadingState()),
        error: (_, _) => unavailable,
      ),
    );
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: 1,
        child: ProductImage(url: detail.imageUrl, cacheWidth: 900),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(detail.name, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ResponsiveCenter(
            maxWidth: 900,
            child: ResponsiveBuilder(
              builder: (context, size) => size == ScreenSize.compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [image, info],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 24,
                      children: [
                        Expanded(flex: 2, child: image),
                        Expanded(flex: 3, child: info),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product, required this.extras});

  final OpenFoodFactsProduct product;
  final Widget? extras;

  @override
  Widget build(BuildContext context) {
    final nutriScore = product.nutriScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(product.name, style: Theme.of(context).textTheme.titleLarge),
        if (nutriScore != null) NutriScorePill(grade: nutriScore),
        Text(
          '${product.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Pill(
              label:
                  'Protéines ${product.proteinsPer100g.toStringAsFixed(1)} g',
              background: AppColors.proteinBg,
              foreground: AppColors.proteinIcon,
            ),
            Pill(
              label: 'Glucides ${product.carbsPer100g.toStringAsFixed(1)} g',
              background: AppColors.carbsBg,
              foreground: AppColors.carbsIcon,
            ),
            Pill(
              label: 'Lipides ${product.fatsPer100g.toStringAsFixed(1)} g',
              background: AppColors.fatBg,
              foreground: AppColors.fatIcon,
            ),
          ],
        ),
        AddToListButton(product: product, label: 'Ajouter à la liste'),
        ?extras,
      ],
    );
  }
}

class _ProductExtras extends StatelessWidget {
  const _ProductExtras({required this.product});

  final OpenFoodFactsProduct product;

  @override
  Widget build(BuildContext context) {
    final ingredients = product.ingredients;
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text('Ingrédients', style: titleStyle),
        Text(
          ingredients == null || ingredients.isEmpty
              ? 'Non renseignés.'
              : ingredients,
        ),
        const SizedBox(height: 4),
        Text('Allergènes', style: titleStyle),
        if (product.allergens.isEmpty)
          const Text('Aucun allergène déclaré.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final allergen in product.allergens)
                Pill(
                  label: allergen,
                  background: AppColors.warningBg,
                  foreground: AppColors.warningText,
                ),
            ],
          ),
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Détails indisponibles pour ce produit.'),
        TextButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    );
  }
}
