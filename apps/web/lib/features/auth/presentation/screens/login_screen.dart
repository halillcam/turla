import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/failure_messages.dart';
import '../bloc/session_bloc.dart';
import '../cubit/login_cubit.dart';
import '../widgets/login_form.dart';

/// Panel giriş ekranı. Başarılı girişte oturum [SessionBloc]'a aktarılır;
/// yönlendirmeyi router yapar.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Açılışta oturum reddedildiyse (rol / pasif firma) nedeni gösterilir.
    final session = context.read<SessionBloc>().state;
    final initialError = session.denial?.message ?? session.failure?.message;

    return BlocProvider(
      create: (_) => getIt<LoginCubit>(),
      child: BlocListener<LoginCubit, LoginState>(
        listenWhen: (previous, current) => current.session != null,
        listener: (context, state) =>
            context.read<SessionBloc>().add(SessionEstablished(state.session!)),
        child: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: AppPaddings.screen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.loginFormMaxWidth),
                child: Card(
                  child: Padding(
                    padding: AppPaddings.allXl,
                    child: BlocBuilder<LoginCubit, LoginState>(
                      builder: (context, state) => LoginForm(
                        isSubmitting: state.isSubmitting,
                        errorMessage:
                            state.denial?.message ??
                            state.failure?.message ??
                            (state.isSubmitting ? null : initialError),
                        onSubmit: (email, password) =>
                            context.read<LoginCubit>().submit(email: email, password: password),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
