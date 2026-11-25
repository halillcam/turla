import 'package:flutter/material.dart';

import '../../../../core/constants/strings.dart';

/// "Kodu elle gir" penceresi. Girilen kodu döndürür (vazgeçilirse null).
class ManualCodeDialog extends StatefulWidget {
  const ManualCodeDialog({super.key});

  static Future<String?> show(BuildContext context) =>
      showDialog<String>(context: context, builder: (_) => const ManualCodeDialog());

  @override
  State<ManualCodeDialog> createState() => _ManualCodeDialogState();
}

class _ManualCodeDialogState extends State<ManualCodeDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isNotEmpty) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.enterCodeTitle),
      content: TextField(
        key: const Key('manual-code-field'),
        controller: _controller,
        autofocus: true,
        autocorrect: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: AppStrings.enterCodeHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.dialogDismiss),
        ),
        TextButton(onPressed: _submit, child: const Text(AppStrings.enterCodeSubmit)),
      ],
    );
  }
}
