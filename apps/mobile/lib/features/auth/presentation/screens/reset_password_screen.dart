import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/submit_button.dart';
import '../cubit/password_reset_cubit.dart';
import '../utils/auth_failure_message.dart';
import '../utils/auth_validators.dart';
import '../widgets/auth_header.dart';
import '../widgets/password_field.dart';

/// Şifre sıfırlama bağlantısıyla açılır (kurtarma oturumu açık): yeni şifre belirlenir.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _again = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ResetPasswordCubit>().save(_password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ResetPasswordCubit>(),
      child: BlocConsumer<ResetPasswordCubit, PasswordResetState>(
        listenWhen: (previous, current) => current.failure != null || current.isDone,
        listener: (context, state) {
          if (state.isDone) {
            AppSnackBar.show(context, AppStrings.passwordUpdated);
            context.go(AppRoutes.tours);
            return;
          }
          AppSnackBar.show(context, state.failure!.message, isError: true);
        },
        builder: (context, state) => Scaffold(
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: AppPaddings.screen,
                children: [
                  const AuthHeader(
                    title: AppStrings.resetPasswordTitle,
                    subtitle: AppStrings.resetPasswordSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PasswordField(
                    controller: _password,
                    label: AppStrings.newPasswordLabel,
                    validator: AuthValidators.newPassword,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PasswordField(
                    controller: _again,
                    label: AppStrings.newPasswordAgainLabel,
                    validator: AuthValidators.passwordConfirmation(() => _password.text),
                    onSubmitted: () => _submit(context),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SubmitButton(
                    label: AppStrings.savePassword,
                    isLoading: state.isSubmitting,
                    onPressed: () => _submit(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
