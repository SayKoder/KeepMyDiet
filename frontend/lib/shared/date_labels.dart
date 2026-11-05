import 'package:intl/intl.dart';

String formatDayLabel(DateTime date) {
  final label = DateFormat('EEEE d MMMM', 'fr_FR').format(date);
  return label[0].toUpperCase() + label.substring(1);
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
