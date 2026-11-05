import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../../../shared/widgets/white_card.dart';
import '../../../nutrition/presentation/profile_controller.dart';
import '../../../nutrition/presentation/water_goal_controller.dart';
import '../../../nutrition/presentation/water_intake_controller.dart';

class WaterCard extends ConsumerWidget {
  const WaterCard({super.key});

  static const _segments = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(waterIntakeControllerProvider);
    final goalOverride = ref.watch(waterGoalControllerProvider).value?.goalMl;
    final profile = ref.watch(profileControllerProvider).value;

    final defaultGoalMl = profile == null
        ? 2000
        : (profile.weightKg * 35 / 50).round() * 50;
    final goalMl = goalOverride ?? defaultGoalMl;
    // En erreur, `.value` contient encore la valeur du jour précédent.
    final amountMl = waterAsync.hasError
        ? 0
        : (waterAsync.value?.amountMl ?? 0);
    final progress = goalMl <= 0 ? 0.0 : (amountMl / goalMl).clamp(0.0, 1.0);
    final isLoading = waterAsync.isLoading && !waterAsync.hasValue;

    void add(int deltaMl) =>
        ref.read(waterIntakeControllerProvider.notifier).add(deltaMl);

    final amountLabel = isLoading
        ? '…'
        : waterAsync.hasError
        ? '—'
        : '$amountMl';

    return WhiteCard(
      child: Column(
        spacing: 14,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconBadge(
              icon: Icons.water_drop_outlined,
              background: AppColors.waterBg,
              foreground: AppColors.waterIcon,
            ),
            title: const Text(
              'Hydratation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '$amountLabel / $goalMl mL',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: waterAsync.hasError
                    ? AppColors.errorText
                    : AppColors.textSecondary,
              ),
            ),
            trailing: IconButton(
              onPressed: () => _showEditGoalDialog(context, ref, goalMl),
              icon: const Icon(
                Icons.settings_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              tooltip: "Modifier l'objectif",
              style: IconButton.styleFrom(
                backgroundColor: AppColors.fieldFill,
                minimumSize: const Size(44, 44),
              ),
            ),
          ),
          Row(
            spacing: 5,
            children: [
              for (var i = 0; i < _segments; i++)
                Expanded(
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: _segmentColor(progress, i),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              _WaterButton(
                label: '−250',
                outlined: true,
                onPressed: isLoading || amountMl <= 0 ? null : () => add(-250),
              ),
              _WaterButton(
                label: '+250 mL',
                background: AppColors.waterBg,
                foreground: const Color(0xFF135F99),
                onPressed: isLoading ? null : () => add(250),
              ),
              _WaterButton(
                label: '+500 mL',
                background: AppColors.waterIcon,
                foreground: Colors.white,
                onPressed: isLoading ? null : () => add(500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _segmentColor(double progress, int index) {
    if (progress >= (index + 1) / _segments) return AppColors.water;
    if (progress > index / _segments) return const Color(0xFFA9D6F8);
    return const Color(0xFFE6F1FB);
  }

  Future<void> _showEditGoalDialog(
    BuildContext context,
    WidgetRef ref,
    int currentGoalMl,
  ) {
    final controller = TextEditingController(text: '$currentGoalMl');
    final goalNotifier = ref.read(waterGoalControllerProvider.notifier);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        void close() => Navigator.of(dialogContext).pop();

        return AlertDialog(
          title: const Text("Objectif d'hydratation"),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Objectif (mL)'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await goalNotifier.reset();
                if (dialogContext.mounted) close();
              },
              child: const Text('Réinitialiser (auto)'),
            ),
            TextButton(onPressed: close, child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final value = int.tryParse(controller.text);
                if (value == null || value <= 0) return;
                await goalNotifier.set(value);
                if (dialogContext.mounted) close();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}

class _WaterButton extends StatelessWidget {
  const _WaterButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.background,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    const minimumSize = Size.fromHeight(44);
    const padding = EdgeInsets.symmetric(horizontal: 4);
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
    final child = Text(label);

    return Expanded(
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: minimumSize,
                padding: padding,
                textStyle: textStyle,
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: background,
                foregroundColor: foreground,
                minimumSize: minimumSize,
                padding: padding,
                textStyle: textStyle,
              ),
              child: child,
            ),
    );
  }
}
