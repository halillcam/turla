import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/new_account.dart';

/// Hesap açma formunun değerleri.
class AccountFormValues {
  const AccountFormValues({required this.fullName, required this.password, this.email, this.phone});

  final String fullName;
  final String password;
  final String? email;
  final String? phone;
}

/// Hesap açma penceresi. [withEmail] true ise (firma admini) e-posta sorulur;
/// rehber ve müşteri için giriş kimliğini sunucu üretir.
///
/// [onSubmit] işlemi yapar; başarılıysa pencere kapanır ve açılan hesap döner.
Future<CreatedAccount?> showAccountFormDialog(
  BuildContext context, {
  required String title,
  required bool withEmail,
  required Future<ActionResult<CreatedAccount>> Function(AccountFormValues values) onSubmit,
}) => showDialog<CreatedAccount>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _AccountFormDialog(title: title, withEmail: withEmail, onSubmit: onSubmit),
);

class _AccountFormDialog extends StatefulWidget {
  const _AccountFormDialog({required this.title, required this.withEmail, required this.onSubmit});

  final String title;
  final bool withEmail;
  final Future<ActionResult<CreatedAccount>> Function(AccountFormValues values) onSubmit;

  @override
  State<_AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<_AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await widget.onSubmit(
      AccountFormValues(
        fullName: _name.text.trim(),
        password: _password.text,
        email: widget.withEmail ? _email.text.trim() : null,
        phone: Validators.nullIfBlank(_phone.text),
      ),
    );
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.pop(context, result.value);
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
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: AppStrings.fullNameLabel),
                validator: Validators.name,
              ),
              if (widget.withEmail) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: AppStrings.emailLabel),
                  validator: Validators.email,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: AppStrings.phoneLabel),
                validator: Validators.optionalPhone,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                  labelText: AppStrings.temporaryPasswordLabel,
                  helperText: AppStrings.temporaryPasswordHelper,
                ),
                validator: Validators.password,
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
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _submitting ? null : _submit, child: const Text(AppStrings.create)),
      ],
    );
  }
}

/// Açılan hesabın giriş bilgisini gösterir.
Future<void> showCreatedAccountDialog(BuildContext context, CreatedAccount account) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.accountCreatedTitle),
        content: SizedBox(
          width: AppSizes.dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (account.loginId != null)
                SelectableText('${AppStrings.accountCreatedLoginId}: ${account.loginId}')
              else
                SelectableText('${AppStrings.accountCreatedEmail}: ${account.email}'),
              const SizedBox(height: AppSpacing.md),
              const Text(AppStrings.accountCreatedHint),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.close),
          ),
        ],
      ),
    );
