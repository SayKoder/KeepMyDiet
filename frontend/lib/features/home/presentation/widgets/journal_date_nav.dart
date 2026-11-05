import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/home/presentation/journal_date_controller.dart';
import 'package:keepmydiet/shared/date_labels.dart';

class JournalDateNav extends ConsumerWidget {
  const JournalDateNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(journalDateProvider);
    final notifier = ref.read(journalDateProvider.notifier);
    final buttonStyle = IconButton.styleFrom(
      backgroundColor: AppColors.fieldFill,
      minimumSize: const Size(40, 40),
    );

    return Row(
      children: [
        IconButton(
          onPressed: notifier.previousDay,
          icon: const Icon(Icons.chevron_left),
          style: buttonStyle,
        ),
        Expanded(
          child: Text(
            formatDayLabel(date),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: notifier.nextDay,
          icon: const Icon(Icons.chevron_right),
          style: buttonStyle,
        ),
      ],
    );
  }
}
