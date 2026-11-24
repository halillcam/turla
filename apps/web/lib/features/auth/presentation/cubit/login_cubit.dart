import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/panel_auth_repository.dart';
import '../../domain/panel_session.dart';

part 'login_state.dart';

/// Panel giriş formu. Rol ve firma kontrolü repository'de yapılır.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._repository) : super(const LoginState());

  final PanelAuthRepository _repository;

  Future<void> submit({required String email, required String password}) async {
    if (state.isSubmitting) return;
    emit(const LoginState(isSubmitting: true));

    try {
      final session = await _repository.signIn(email: email, password: password);
      emit(LoginState(session: session));
    } on PanelAccessDenied catch (denied) {
      emit(LoginState(denial: denied.denial));
    } on AuthFailure catch (failure) {
      emit(LoginState(failure: failure.reason));
    }
  }
}
