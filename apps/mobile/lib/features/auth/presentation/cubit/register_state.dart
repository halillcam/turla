part of 'register_cubit.dart';

enum RegisterStatus { idle, submitting, signedIn, confirmationRequired, failure }

final class RegisterState extends Equatable {
  const RegisterState({this.status = RegisterStatus.idle, this.failure});

  final RegisterStatus status;
  final AuthFailureReason? failure;

  bool get isSubmitting => status == RegisterStatus.submitting;

  @override
  List<Object?> get props => [status, failure];
}
