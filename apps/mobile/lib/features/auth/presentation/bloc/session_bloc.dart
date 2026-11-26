import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/session/session_cleanup.dart';

part 'session_event.dart';
part 'session_state.dart';

/// Uygulama genelinde oturum durumu: misafir mi, giriş yapmış mı, rolü ne.
///
/// Mobil uygulamaya sadece müşteri ve tur sorumlusu girebilir; admin veya
/// super admin hesabıyla açılan oturum kapatılır.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc(this._authRepository, {List<SessionCleanup> cleanups = const []})
    : _cleanupSteps = cleanups,
      super(const SessionState.unknown()) {
    on<SessionStarted>(_onStarted);
    on<SessionRefreshRequested>(_onRefreshRequested);
    on<SessionSignOutRequested>(_onSignOutRequested);
  }

  final AuthRepository _authRepository;

  /// Çıkışta push token'ını ayırır ve kullanıcıya özel önbellekleri siler.
  final List<SessionCleanup> _cleanupSteps;
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
    final userId = state.profile?.id;
    if (userId != null) {
      for (final cleanup in _cleanupSteps) {
        await _safely(() => cleanup.beforeSignOut(userId));
      }
    }
    try {
      await _authRepository.signOut();
    } on AuthFailure {
      // Ağ yoksa bile yerel oturum kapanır; misafir olarak devam edilir.
    }
    if (userId != null) {
      for (final cleanup in _cleanupSteps) {
        await _safely(() => cleanup.afterSignOut(userId));
      }
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

  /// Temizlik hatası çıkışı engellemez.
  static Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Yok sayılır.
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
