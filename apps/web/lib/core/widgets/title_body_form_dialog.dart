import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../bloc/load_status.dart';
import '../constants/strings.dart';
import '../utils/failure_messages.dart';
import '../utils/validators.dart';

/// Başlık + metin girilen pencere (duyuru, geri bildirim). [targets] verilirse
/// başlığın üstünde hedef seçimi çıkar (ör. "Tüm firmalar" / tek firma; null = ilk seçenek).
/// [onSubmit] başarılıysa pencere kapanır.
Future<bool> showTitleBodyFormDialog(
  BuildContext context, {
  required String title,
  required String submitLabel,
  required int titleMaxLength,
  required int bodyMaxLength,
  required Future<ActionResult<Object?>> Function(String title, String body, String? target)
  onSubmit,
  List<({String? value, String label})> targets = const [],
  String? targetLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TitleBodyFormDialog(
        title: title,
        submitLabel: submitLabel,
        titleMaxLength: titleMaxLength,
        bodyMaxLength: bodyMaxLength,
        onSubmit: onSubmit,
        targets: targets,
        targetLabel: targetLabel,
      ),
    ) ??
    false;

class _TitleBodyFormDialog extends StatefulWidget {
  const _TitleBodyFormDialog({
    required this.title,
    required this.submitLabel,
    required this.titleMaxLength,
    required this.bodyMaxLength,
    required this.onSubmit,
    required this.targets,
    this.targetLabel,
  });

  final String title;
  final String submitLabel;
  final int titleMaxLength;
  final int bodyMaxLength;
  final Future<ActionResult<Object?>> Function(String title, String body, String? target) onSubmit;
  final List<({String? value, String label})> targets;
  final String? targetLabel;

  @override
  State<_TitleBodyFormDialog> createState() => _TitleBodyFormDialogState();
}

class _TitleBodyFormDialogState extends State<_TitleBodyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  late String? _target = widget.targets.isEmpty ? null : widget.targets.first.value;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await widget.onSubmit(_title.text, _body.text, _target);
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _submitting = false;
        _error = result.failure!.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.targets.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  style: PanelTextStyles.body,
                  menuMaxHeight: AppSizes.dropdownMenuMaxHeight,
                  initialValue: _target,
                  decoration: InputDecoration(labelText: widget.targetLabel),
                  items: [
                    for (final target in widget.targets)
                      DropdownMenuItem(value: target.value, child: Text(target.label)),
                  ],
                  onChanged: (value) => setState(() => _target = value),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                controller: _title,
                maxLength: widget.titleMaxLength,
                decoration: const InputDecoration(labelText: AppStrings.messageTitleLabel),
                validator: Validators.title,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _body,
                maxLength: widget.bodyMaxLength,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: AppStrings.messageBodyLabel),
                validator: Validators.required,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _submitting ? null : _submit, child: Text(widget.submitLabel)),
      ],
    );
  }
}
