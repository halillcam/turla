part of 'login_cubit.dart';

final class LoginState extends Equatable {
  const LoginState({this.isSubmitting = false, this.session, this.failure, this.denial});

  final bool isSubmitting;

  /// Giriş başarılıysa oturum.
  final PanelSession? session;
  final AuthFailureReason? failure;
  final PanelDenial? denial;

  @override
  List<Object?> get props => [isSubmitting, session, failure, denial];
}
