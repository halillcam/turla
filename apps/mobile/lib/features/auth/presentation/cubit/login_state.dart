part of 'login_cubit.dart';

final class LoginState extends Equatable {
  const LoginState({this.isSubmitting = false, this.signedInRole, this.failure});

  final bool isSubmitting;

  /// Giriş başarılıysa kullanıcının rolü; ekran buna göre yönlendirme yapar.
  final UserRole? signedInRole;
  final AuthFailureReason? failure;

  bool get isSuccess => signedInRole != null;

  @override
  List<Object?> get props => [isSubmitting, signedInRole, failure];
}
