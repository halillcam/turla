part of 'session_bloc.dart';

sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

/// Uygulama açılışında bir kez gönderilir.
final class SessionStarted extends SessionEvent {
  const SessionStarted();
}

/// Giriş ekranında giriş başarılı oldu.
final class SessionEstablished extends SessionEvent {
  const SessionEstablished(this.session);

  final PanelSession session;

  @override
  List<Object?> get props => [session];
}

/// Oturum dışarıdan kapandı.
final class SessionEnded extends SessionEvent {
  const SessionEnded();
}

final class SessionSignOutRequested extends SessionEvent {
  const SessionSignOutRequested();
}
