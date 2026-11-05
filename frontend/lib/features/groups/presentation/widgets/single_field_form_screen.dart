import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:keepmydiet/shared/api_client.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';

class SingleFieldFormScreen extends StatefulWidget {
  const SingleFieldFormScreen({
    super.key,
    required this.title,
    required this.fieldLabel,
    required this.submitLabel,
    required this.emptyError,
    required this.onSubmit,
    this.intro,
  });

  final String title;
  final String fieldLabel;
  final String submitLabel;
  final String emptyError;
  final String? intro;
  final Future<void> Function(String value) onSubmit;

  @override
  State<SingleFieldFormScreen> createState() => _SingleFieldFormScreenState();
}

class _SingleFieldFormScreenState extends State<SingleFieldFormScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorMessage = widget.emptyError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(value);
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() => _errorMessage = extractErrorMessage(e));
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            if (widget.intro != null) Text(widget.intro!),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(labelText: widget.fieldLabel),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              FormErrorText(_errorMessage!, padding: EdgeInsets.zero),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: SubmitButtonContent(
                isSubmitting: _isSubmitting,
                label: Text(widget.submitLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
