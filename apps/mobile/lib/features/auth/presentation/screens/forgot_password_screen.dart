import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/submit_button.dart';
import '../cubit/password_reset_cubit.dart';
import '../utils/auth_failure_message.dart';
import '../utils/auth_validators.dart';
import '../widgets/auth_header.dart';

/// "Şifremi unuttum": e-postaya sıfırlama bağlantısı gönderilir. Bağlantı uygulamayı
/// açınca yeni şifre ekranı gelir ([ResetPasswordScreen]).
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ForgotPasswordCubit>(),
      child: BlocConsumer<ForgotPasswordCubit, PasswordResetState>(
        listenWhen: (previous, current) => current.failure != null,
        listener: (context, state) =>
            AppSnackBar.show(context, state.failure!.message, isError: true),
        builder: (context, state) => Scaffold(
          appBar: AppBar(shape: const Border()),
          body: SafeArea(
            child: ListView(
              padding: AppPaddings.screen,
              children: [
                const AuthHeader(
                  title: AppStrings.forgotPasswordTitle,
                  subtitle: AppStrings.forgotPasswordSubtitle,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (state.isDone)
                  const ToneBanner(
                    title: AppStrings.resetLinkSentTitle,
                    message: AppStrings.resetLinkSentMessage,
                    icon: Icons.mark_email_read_outlined,
                    tone: AppTone.success,
                  )
                else
                  _EmailForm(isSubmitting: state.isSubmitting),
                const SizedBox(height: AppSpacing.lg),
                Text(AppStrings.staffResetHint, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailForm extends StatefulWidget {
  const _EmailForm({required this.isSubmitting});

  final bool isSubmitting;

  @override
  State<_EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<_EmailForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ForgotPasswordCubit>().send(_email.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: AuthValidators.email,
            decoration: const InputDecoration(labelText: AppStrings.emailLabel),
          ),
          const SizedBox(height: AppSpacing.xl),
          SubmitButton(
            label: AppStrings.sendResetLink,
            isLoading: widget.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
