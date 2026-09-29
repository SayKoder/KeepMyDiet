import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keepmydiet/features/auth/data/token_storage.dart';
import 'package:keepmydiet/main.dart';

/// Remplace le vrai stockage sécurisé (canaux natifs, indisponibles en test)
/// par une version en mémoire — Riverpod permet ce genre de substitution via
/// `overrides`, sans toucher au code de l'app.
class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage() : super(const FlutterSecureStorage());

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}

void main() {
  testWidgets('Sans session, l\'app affiche l\'écran de connexion', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())],
        child: const KeepMyDietApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connexion'), findsOneWidget);
  });
}
