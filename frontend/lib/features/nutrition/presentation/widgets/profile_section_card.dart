import 'package:flutter/material.dart';

import 'package:keepmydiet/core/theme.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      radius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          ...children,
        ],
      ),
    );
  }
}
