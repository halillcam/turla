import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

part 'register_state.dart';

/// Müşteri kaydı. E-posta doğrulaması kapalıysa kayıttan sonra oturum açılır,
/// açıksa kullanıcıya e-postasını kontrol etmesi söylenir.
class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this._authRepository) : super(const RegisterState());

  final AuthRepository _authRepository;

  Future<void> submit({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (state.status == RegisterStatus.submitting) return;
    emit(const RegisterState(status: RegisterStatus.submitting));

    try {
      final result = await _authRepository.signUpCustomer(
        fullName: fullName,
        email: email,
        password: password,
      );
      emit(
        RegisterState(
          status: result.requiresEmailConfirmation
              ? RegisterStatus.confirmationRequired
              : RegisterStatus.signedIn,
        ),
      );
    } on AuthFailure catch (failure) {
      emit(RegisterState(status: RegisterStatus.failure, failure: failure.reason));
    }
  }
}
