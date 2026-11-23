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

/// Oturum değiştiğinde (giriş/çıkış) profil yeniden yüklenir.
final class SessionRefreshRequested extends SessionEvent {
  const SessionRefreshRequested();
}

final class SessionSignOutRequested extends SessionEvent {
  const SessionSignOutRequested();
}
