import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/status_view.dart';
import '../cubit/register_cubit.dart';
import '../utils/auth_failure_message.dart';
import '../utils/auth_navigation.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_header.dart';
import '../widgets/register_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RegisterCubit>(),
      child: BlocConsumer<RegisterCubit, RegisterState>(
        listenWhen: (previous, current) =>
            current.status == RegisterStatus.failure || current.status == RegisterStatus.signedIn,
        listener: (context, state) {
          if (state.status == RegisterStatus.signedIn) {
            // Mobilden kayıt olan her zaman müşteridir.
            AuthNavigation.afterSignIn(context, UserRole.customer);
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.failure!.message)));
        },
        builder: (context, state) {
          if (state.status == RegisterStatus.confirmationRequired) {
            return Scaffold(
              appBar: AppBar(title: const Text(AppStrings.confirmationSentTitle)),
              body: StatusView.message(
                message: AppStrings.confirmationSentMessage,
                icon: Icons.mark_email_read_outlined,
                actionLabel: AppStrings.goToLogin,
                onAction: () => context.pushReplacement(AppRoutes.login),
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(),
            body: SafeArea(
              child: ListView(
                padding: AppPaddings.screen,
                children: [
                  const AuthHeader(
                    title: AppStrings.registerTitle,
                    subtitle: AppStrings.registerSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const RegisterForm(),
                  const SizedBox(height: AppSpacing.md),
                  AuthFooterLink(
                    question: AppStrings.haveAccount,
                    actionLabel: AppStrings.goToLogin,
                    onPressed: () => context.pushReplacement(AppRoutes.login),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
