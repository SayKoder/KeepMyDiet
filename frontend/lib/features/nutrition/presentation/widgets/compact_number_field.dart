import 'package:flutter/material.dart';

import '../../../../core/theme.dart';

class CompactNumberField extends StatelessWidget {
  const CompactNumberField({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
  });

  final String label;
  final String unit;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
