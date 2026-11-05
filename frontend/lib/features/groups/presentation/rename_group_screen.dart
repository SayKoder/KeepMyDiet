import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keepmydiet/features/groups/domain/group.dart';
import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/features/groups/presentation/widgets/single_field_form_screen.dart';

class RenameGroupScreen extends ConsumerWidget {
  const RenameGroupScreen({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleFieldFormScreen(
      title: 'Renommer le groupe',
      fieldLabel: 'Nom du groupe',
      submitLabel: 'Enregistrer',
      emptyError: 'Le nom ne peut pas être vide.',
      initialValue: group.name,
      onSubmit: (name) =>
          ref.read(groupsControllerProvider.notifier).renameGroup(group, name),
    );
  }
}
