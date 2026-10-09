import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Jour actuellement affiché sur l'Accueil (journal quotidien) — normalisé à
/// minuit pour que la comparaison avec les dates renvoyées par le backend
/// (elles aussi normalisées à minuit) soit fiable.
class JournalDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _today();

  void previousDay() => state = state.subtract(const Duration(days: 1));

  void nextDay() => state = state.add(const Duration(days: 1));
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

final journalDateProvider = NotifierProvider<JournalDateNotifier, DateTime>(
  JournalDateNotifier.new,
);

/// Pratique pour l'UI : désactiver/masquer ce qui n'a de sens que pour
/// aujourd'hui (si jamais), sans que chaque écran recalcule `_today()`.
final isJournalTodayProvider = Provider<bool>(
  (ref) => ref.watch(journalDateProvider) == _today(),
);
