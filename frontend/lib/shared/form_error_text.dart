import 'package:flutter/material.dart';

/// Message d'erreur sous un formulaire ("nom vide", échec réseau...) — même
/// padding/style recopiés dans la quasi-totalité des formulaires
/// d'ajout/création de l'appli.
class FormErrorText extends StatelessWidget {
  const FormErrorText(
    this.message, {
    super.key,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final String message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
