part of 'session_bloc.dart';

enum SessionStatus { unknown, guest, signedIn }

final class SessionState extends Equatable {
  const SessionState._({required this.status, this.session, this.failure, this.denial});

  /// Açılışta oturum henüz kontrol edilmedi.
  const SessionState.unknown() : this._(status: SessionStatus.unknown);

  /// Giriş yapılmamış. [failure] / [denial] varsa giriş ekranında nedeni gösterilir.
  const SessionState.guest({AuthFailureReason? failure, PanelDenial? denial})
    : this._(status: SessionStatus.guest, failure: failure, denial: denial);

  const SessionState.signedIn(PanelSession session)
    : this._(status: SessionStatus.signedIn, session: session);

  final SessionStatus status;
  final PanelSession? session;
  final AuthFailureReason? failure;
  final PanelDenial? denial;

  bool get isSignedIn => status == SessionStatus.signedIn;

  @override
  List<Object?> get props => [status, session, failure, denial];
}
