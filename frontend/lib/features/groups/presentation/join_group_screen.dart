import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keepmydiet/features/groups/data/groups_api_client.dart';
import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/features/groups/presentation/widgets/single_field_form_screen.dart';

class JoinGroupScreen extends ConsumerWidget {
  const JoinGroupScreen({super.key});

  Future<void> _join(WidgetRef ref, String token) async {
    await ref.read(groupsApiClientProvider).joinByToken(token);
    await ref.read(groupsControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleFieldFormScreen(
      title: 'Rejoindre un groupe',
      intro: "Colle le code d'invitation reçu de la personne qui t'invite.",
      fieldLabel: "Code d'invitation",
      submitLabel: 'Rejoindre',
      emptyError: 'Colle le code reçu.',
      onSubmit: (token) => _join(ref, token),
    );
  }
}
