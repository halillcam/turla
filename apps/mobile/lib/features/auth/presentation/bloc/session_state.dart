part of 'session_bloc.dart';

enum SessionStatus { unknown, guest, signedIn }

final class SessionState extends Equatable {
  const SessionState._({required this.status, this.profile, this.notice});

  /// Açılışta oturum henüz kontrol edilmedi.
  const SessionState.unknown() : this._(status: SessionStatus.unknown);

  /// Giriş yapılmamış. [notice] varsa kullanıcıya neden çıkış yapıldığı gösterilir.
  const SessionState.guest({AuthFailureReason? notice})
    : this._(status: SessionStatus.guest, notice: notice);

  const SessionState.signedIn(UserProfile profile)
    : this._(status: SessionStatus.signedIn, profile: profile);

  final SessionStatus status;
  final UserProfile? profile;
  final AuthFailureReason? notice;

  bool get isSignedIn => status == SessionStatus.signedIn;
  bool get isGuide => profile?.role == UserRole.guide;

  @override
  List<Object?> get props => [status, profile, notice];
}
