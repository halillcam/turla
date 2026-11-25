import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../cubit/login_cubit.dart';
import '../utils/auth_validators.dart';
import 'password_field.dart';
import '../../../../core/widgets/submit_button.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<LoginCubit>().submit(
      identity: _identityController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select((LoginCubit cubit) => cubit.state.isSubmitting);

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _identityController,
              validator: AuthValidators.required,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              decoration: const InputDecoration(
                labelText: AppStrings.identityLabel,
                hintText: AppStrings.identityHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PasswordField(
              controller: _passwordController,
              label: AppStrings.passwordLabel,
              validator: AuthValidators.required,
              onSubmitted: _submit,
            ),
            const SizedBox(height: AppSpacing.xl),
            SubmitButton(
              label: AppStrings.loginButton,
              isLoading: isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
