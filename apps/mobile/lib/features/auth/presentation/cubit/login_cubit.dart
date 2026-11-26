import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

part 'login_state.dart';

/// Giriş formu. Girilen değer e-posta ise müşteri girişi, değilse panelden
/// verilen giriş kimliği (rehber / dışarıdan eklenen yolcu) ile giriş yapılır.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._authRepository) : super(const LoginState());

  final AuthRepository _authRepository;

  Future<void> submit({required String identity, required String password}) async {
    if (state.isSubmitting) return;
    emit(const LoginState(isSubmitting: true));

    try {
      final profile = LoginId.looksLikeLoginId(identity)
          ? await _authRepository.signInWithLoginId(loginId: identity, password: password)
          : await _authRepository.signInWithEmail(email: identity, password: password);

      // Giriş sırasında ekran kapandıysa (ör. kullanıcı geri bastı) durum yayınlanmaz.
      if (isClosed) return;
      if (!profile.role.canUseMobileApp) {
        await _authRepository.signOut();
        emit(const LoginState(failure: AuthFailureReason.roleNotAllowed));
        return;
      }
      emit(LoginState(signedInRole: profile.role));
    } on AuthFailure catch (failure) {
      if (isClosed) return;
      emit(LoginState(failure: failure.reason));
    }
  }
}
