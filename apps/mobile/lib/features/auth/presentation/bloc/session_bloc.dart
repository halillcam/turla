import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

part 'session_event.dart';
part 'session_state.dart';

/// Uygulama genelinde oturum durumu: misafir mi, giriş yapmış mı, rolü ne.
///
/// Mobil uygulamaya sadece müşteri ve tur sorumlusu girebilir; admin veya
/// super admin hesabıyla açılan oturum kapatılır.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc(this._authRepository) : super(const SessionState.unknown()) {
    on<SessionStarted>(_onStarted);
    on<SessionRefreshRequested>(_onRefreshRequested);
    on<SessionSignOutRequested>(_onSignOutRequested);
  }

  final AuthRepository _authRepository;
  StreamSubscription<void>? _authSubscription;

  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) async {
    await _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen(
      (_) => add(const SessionRefreshRequested()),
    );
    await _loadProfile(emit);
  }

  Future<void> _onRefreshRequested(SessionRefreshRequested event, Emitter<SessionState> emit) =>
      _loadProfile(emit);

  Future<void> _onSignOutRequested(
    SessionSignOutRequested event,
    Emitter<SessionState> emit,
  ) async {
    try {
      await _authRepository.signOut();
    } on AuthFailure {
      // Ağ yoksa bile yerel oturum kapanır; misafir olarak devam edilir.
    }
    emit(const SessionState.guest());
  }

  Future<void> _loadProfile(Emitter<SessionState> emit) async {
    try {
      final profile = await _authRepository.currentProfile();
      if (profile == null) {
        emit(const SessionState.guest());
        return;
      }
      if (!profile.role.canUseMobileApp) {
        await _authRepository.signOut();
        emit(const SessionState.guest(notice: AuthFailureReason.roleNotAllowed));
        return;
      }
      emit(SessionState.signedIn(profile));
    } on AuthFailure catch (failure) {
      emit(SessionState.guest(notice: failure.reason));
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
