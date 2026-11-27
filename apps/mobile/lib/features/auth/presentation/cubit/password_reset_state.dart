part of 'password_reset_cubit.dart';

final class PasswordResetState extends Equatable {
  const PasswordResetState({this.isSubmitting = false, this.isDone = false, this.failure});

  final bool isSubmitting;

  /// Bağlantı gönderildi / şifre kaydedildi.
  final bool isDone;
  final AuthFailureReason? failure;

  @override
  List<Object?> get props => [isSubmitting, isDone, failure];
}
