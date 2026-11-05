import 'package:flutter/material.dart';

class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.decimal = true,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final bool decimal;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}
