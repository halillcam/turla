part of 'login_cubit.dart';

final class LoginState extends Equatable {
  const LoginState({this.isSubmitting = false, this.isSuccess = false, this.failure});

  final bool isSubmitting;
  final bool isSuccess;
  final AuthFailureReason? failure;

  @override
  List<Object?> get props => [isSubmitting, isSuccess, failure];
}
