import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/validators.dart';

/// E-posta + şifre formu. Sadece alanları toplar; giriş işini [onSubmit] yapar.
class LoginForm extends StatefulWidget {
  const LoginForm({
    required this.isSubmitting,
    required this.onSubmit,
    this.errorMessage,
    super.key,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final void Function(String email, String password) onSubmit;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(AppStrings.panelTitle, style: PanelTextStyles.wordmark),
          const SizedBox(height: AppSpacing.sm),
          const Text(AppStrings.loginTitle, style: PanelTextStyles.pageTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.loginSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: AppStrings.emailLabel),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _password,
            decoration: const InputDecoration(labelText: AppStrings.passwordLabel),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            validator: Validators.required,
            onFieldSubmitted: (_) => _submit(),
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ToneBanner(
              message: widget.errorMessage!,
              tone: AppTone.error,
              icon: Icons.error_outline,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: widget.isSubmitting ? null : _submit,
            child: widget.isSubmitting
                ? const SizedBox.square(
                    dimension: AppSizes.iconMd,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.progressStroke,
                      color: AppColors.textSecondary,
                    ),
                  )
                : const Text(AppStrings.loginButton),
          ),
        ],
      ),
    );
  }
}
