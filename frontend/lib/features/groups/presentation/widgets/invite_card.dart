import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/features/groups/data/groups_api_client.dart';
import 'package:keepmydiet/features/groups/domain/group.dart';
import 'package:keepmydiet/shared/api_client.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class InviteCard extends ConsumerStatefulWidget {
  const InviteCard({super.key, required this.group});

  final Group group;

  @override
  ConsumerState<InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends ConsumerState<InviteCard> {
  String? _token;
  bool _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final invitation = await ref
          .read(groupsApiClientProvider)
          .createInvitation(widget.group.id);
      if (mounted) setState(() => _token = invitation.token);
    } on DioException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _copy() => Clipboard.setData(ClipboardData(text: _token!));

  @override
  Widget build(BuildContext context) {
    final hasToken = _token != null;

    return WhiteCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          "Code d'invitation · ${widget.group.name}",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        subtitle: Text(
          _token ?? 'Pas encore généré',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: hasToken ? 2 : 0,
            color: hasToken ? AppColors.ink : AppColors.textSecondary,
          ),
        ),
        trailing: FilledButton.icon(
          onPressed: _isGenerating ? null : (hasToken ? _copy : _generate),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.ink,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: Icon(hasToken ? Icons.copy : Icons.vpn_key, size: 16),
          label: Text(hasToken ? 'Copier' : 'Générer'),
        ),
      ),
    );
  }
}
