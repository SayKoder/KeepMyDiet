import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/features/groups/presentation/widgets/single_field_form_screen.dart';

class CreateGroupScreen extends ConsumerWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleFieldFormScreen(
      title: 'Créer un groupe',
      fieldLabel: 'Nom du groupe',
      submitLabel: 'Créer',
      emptyError: 'Le nom ne peut pas être vide.',
      onSubmit: (name) =>
          ref.read(groupsControllerProvider.notifier).createGroup(name: name),
    );
  }
}
