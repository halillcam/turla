import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

part 'password_reset_state.dart';

/// "Şifremi unuttum": e-postaya sıfırlama bağlantısı gönderir.
class ForgotPasswordCubit extends Cubit<PasswordResetState> {
  ForgotPasswordCubit(this._authRepository) : super(const PasswordResetState());

  final AuthRepository _authRepository;

  Future<void> send(String email) async {
    if (state.isSubmitting) return;
    emit(const PasswordResetState(isSubmitting: true));
    try {
      await _authRepository.sendPasswordReset(email);
      if (!isClosed) emit(const PasswordResetState(isDone: true));
    } on AuthFailure catch (failure) {
      if (!isClosed) emit(PasswordResetState(failure: failure.reason));
    }
  }
}

/// Sıfırlama bağlantısıyla açılan oturumda yeni şifreyi kaydeder.
class ResetPasswordCubit extends Cubit<PasswordResetState> {
  ResetPasswordCubit(this._authRepository) : super(const PasswordResetState());

  final AuthRepository _authRepository;

  Future<void> save(String newPassword) async {
    if (state.isSubmitting) return;
    emit(const PasswordResetState(isSubmitting: true));
    try {
      await _authRepository.updatePassword(newPassword);
      if (!isClosed) emit(const PasswordResetState(isDone: true));
    } on AuthFailure catch (failure) {
      if (!isClosed) emit(PasswordResetState(failure: failure.reason));
    }
  }
}
