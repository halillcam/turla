import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/panel_auth_repository.dart';
import '../../domain/panel_session.dart';

part 'session_event.dart';
part 'session_state.dart';

/// Panel genelindeki oturum durumu.
///
/// Açılışta mevcut oturum kontrol edilir. Giriş başarılı olunca giriş ekranı
/// [SessionEstablished] gönderir (profil ikinci kez sunucudan okunmaz).
/// Oturum başka bir yerden kapanırsa misafire dönülür.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc(this._repository) : super(const SessionState.unknown()) {
    on<SessionStarted>(_onStarted);
    on<SessionEstablished>((event, emit) => emit(SessionState.signedIn(event.session)));
    on<SessionEnded>((event, emit) => emit(const SessionState.guest()));
    on<SessionSignOutRequested>(_onSignOutRequested);
  }

  final PanelAuthRepository _repository;
  StreamSubscription<void>? _signedOutSubscription;

  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) async {
    await _signedOutSubscription?.cancel();
    _signedOutSubscription = _repository.signedOut.listen((_) => add(const SessionEnded()));

    try {
      final session = await _repository.currentSession();
      emit(session == null ? const SessionState.guest() : SessionState.signedIn(session));
    } on PanelAccessDenied catch (denied) {
      emit(SessionState.guest(denial: denied.denial));
    } on AuthFailure catch (failure) {
      emit(SessionState.guest(failure: failure.reason));
    }
  }

  Future<void> _onSignOutRequested(
    SessionSignOutRequested event,
    Emitter<SessionState> emit,
  ) async {
    try {
      await _repository.signOut();
    } on AuthFailure {
      // Ağ yoksa bile yerel oturum kapanır.
    }
    emit(const SessionState.guest());
  }

  @override
  Future<void> close() async {
    await _signedOutSubscription?.cancel();
    return super.close();
  }
}
