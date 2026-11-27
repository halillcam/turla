import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/di/injection.dart';
import '../cubit/login_cubit.dart';
import '../utils/auth_failure_message.dart';
import '../utils/auth_navigation.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_header.dart';
import '../widgets/login_form.dart';

/// Başarılı girişten sonra ekran [AuthNavigation] ile kapatılır.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoginCubit>(),
      child: BlocListener<LoginCubit, LoginState>(
        listenWhen: (previous, current) => current.failure != null || current.isSuccess,
        listener: (context, state) {
          final role = state.signedInRole;
          if (role != null) {
            AuthNavigation.afterSignIn(context, role);
            return;
          }
          AppSnackBar.show(context, state.failure!.message, isError: true);
        },
        child: Scaffold(
          appBar: AppBar(shape: const Border()),
          body: SafeArea(
            child: ListView(
              padding: AppPaddings.screen,
              children: [
                const AuthHeader(title: AppStrings.loginTitle, subtitle: AppStrings.loginSubtitle),
                const SizedBox(height: AppSpacing.xl),
                const LoginForm(),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    style: TextButton.styleFrom(textStyle: AppTextStyles.labelMedium),
                    child: const Text(AppStrings.forgotPassword),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AuthFooterLink(
                  question: AppStrings.noAccount,
                  actionLabel: AppStrings.goToRegister,
                  onPressed: () => context.pushReplacement(AppRoutes.register),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.tours),
                  child: const Text(AppStrings.continueAsGuest),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
