import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:keepmydiet/core/riverpod_config.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/fridge/data/open_food_facts_client.dart';
import 'package:keepmydiet/shared/responsive.dart';

const phonePortrait = Size(390, 844);
const phoneLandscape = Size(844, 390);
const tabletPortrait = Size(800, 1280);
const tabletLandscape = Size(1280, 800);

OpenFoodFactsProduct product(String name, {String? barcode}) =>
    OpenFoodFactsProduct(
      name: name,
      caloriesPer100g: 120,
      proteinsPer100g: 4.5,
      carbsPer100g: 12.2,
      fatsPer100g: 3.1,
      barcode: barcode ?? name.hashCode.toString(),
    );

DioException networkError() => DioException(
  requestOptions: RequestOptions(),
  type: DioExceptionType.connectionError,
);

class FakeOpenFoodFacts extends OpenFoodFactsClient {
  FakeOpenFoodFacts({this.onBrowse, this.onProduct}) : super(Dio());

  final Future<OpenFoodFactsPage> Function(String query, int page)? onBrowse;
  final Future<OpenFoodFactsProduct?> Function(String barcode)? onProduct;

  @override
  Future<OpenFoodFactsPage> browse(String query, {int page = 1}) =>
      onBrowse!(query, page);

  @override
  Future<OpenFoodFactsProduct?> product(String barcode) => onProduct!(barcode);
}

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = phonePortrait,
  double textScale = 1,
  double keyboardHeight = 0,
  List<Override> overrides = const [],
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..viewInsets = FakeViewPadding(bottom: keyboardHeight);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      retry: noAutoRetry,
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: ResponsiveCenter(child: child!),
        ),
        home: screen,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> disposeScreen(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox());
