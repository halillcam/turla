import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/search_normalizer.dart';
import '../../domain/entities/check_in_result.dart';
import '../../domain/entities/guide_departure.dart';
import '../../domain/entities/guide_failure.dart';
import '../../domain/entities/participant.dart';
import '../../domain/repositories/guide_repository.dart';

part 'departure_state.dart';

/// Bir kalkışın katılımcı listesi, elle "Geldi" ve "Turu bitir".
///
/// Liste ekran açılınca ve aşağı çekince sunucudan gelir; arama ve süzme cihazda.
class DepartureCubit extends Cubit<DepartureState> {
  DepartureCubit(this._repository, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now,
      super(const DepartureState()) {
    _subscription = _repository.departureChanges.listen(_onDeparturesChanged);
  }

  final GuideRepository _repository;
  final DateTime Function() _now;
  late final StreamSubscription<List<GuideDeparture>> _subscription;
  String? _departureId;

  Future<void> load(String departureId) async {
    _departureId = departureId;
    var departure = (await _repository.getCachedDepartures())
        ?.where((departure) => departure.id == departureId)
        .firstOrNull;
    final cachedParticipants = await _repository.getCachedParticipants(departureId);
    if (isClosed) return;

    if (departure == null) {
      // Cihazda yoksa (ör. önbellek silinmiş) kalkışlar bir kez sunucudan çekilir.
      try {
        departure = (await _repository.refreshDepartures())
            .where((departure) => departure.id == departureId)
            .firstOrNull;
      } on GuideFailure catch (failure) {
        if (!isClosed) {
          emit(state.copyWith(status: DepartureViewStatus.failure, failure: failure.reason));
        }
        return;
      }
      if (isClosed) return;
      if (departure == null) {
        emit(state.copyWith(status: DepartureViewStatus.notFound));
        return;
      }
    }

    emit(
      state.copyWith(
        departure: departure,
        participants: cachedParticipants,
        status: cachedParticipants == null
            ? DepartureViewStatus.loading
            : DepartureViewStatus.ready,
        canRequestCompletion: departure.canRequestCompletionAt(_now()),
      ),
    );
    await _refreshParticipants();
  }

  /// Aşağı çekince: katılımcılar ve (firma onay/ret vermiş olabilir) kalkış durumu.
  Future<void> refresh() async {
    try {
      await _repository.refreshDepartures();
    } on GuideFailure {
      // Katılımcı yenilemesi aynı hatayı gösterecek.
    }
    await _refreshParticipants();
  }

  void setFilter(ParticipantFilter filter) => emit(state.copyWith(filter: filter));

  void search(String query) => emit(state.copyWith(query: query));

  /// Okutma ekranından dönünce (bir şey okutulduysa) cihazdaki liste yeniden okunur; istek atılmaz.
  Future<void> reloadFromDevice() async {
    final departureId = _departureId;
    if (departureId == null) return;
    final participants = await _repository.getCachedParticipants(departureId);
    if (isClosed || participants == null) return;
    emit(state.copyWith(participants: participants));
  }

  Future<void> checkInManually(Participant participant) async {
    if (state.actionStatus == DepartureAction.inProgress) return;
    emit(state.copyWith(actionStatus: DepartureAction.inProgress));
    try {
      final result = await _repository.checkInManually(participant.ticketId);
      if (isClosed) return;
      final participants = result.isSuccess
          ? [
              for (final other in state.participants)
                other.ticketId == participant.ticketId
                    ? other.checkedIn(result.scannedAt ?? _now(), CheckInMethod.manual)
                    : other,
            ]
          : state.participants;
      emit(
        state.copyWith(
          participants: participants,
          actionStatus: DepartureAction.idle,
          lastCheckIn: result,
        ),
      );
    } on GuideFailure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(actionStatus: DepartureAction.failure, actionFailure: failure.reason));
    }
  }

  Future<void> requestCompletion() async {
    final departure = state.departure;
    if (departure == null || state.actionStatus == DepartureAction.inProgress) return;
    emit(state.copyWith(actionStatus: DepartureAction.inProgress));
    try {
      await _repository.requestCompletion(departure.id);
      if (isClosed) return;
      // Kalkış durumu departureChanges ile güncellenir.
      emit(state.copyWith(actionStatus: DepartureAction.completionRequested));
    } on GuideFailure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(actionStatus: DepartureAction.failure, actionFailure: failure.reason));
    }
  }

  /// Gösterilen sonuç/hata mesajı okundu.
  void clearAction() => emit(state.copyWith(actionStatus: DepartureAction.idle));

  Future<void> _refreshParticipants() async {
    final departureId = _departureId;
    if (departureId == null) return;
    try {
      final participants = await _repository.refreshParticipants(departureId);
      if (isClosed) return;
      emit(
        state.copyWith(
          participants: participants,
          status: DepartureViewStatus.ready,
          isStale: false,
        ),
      );
    } on GuideFailure catch (failure) {
      if (isClosed) return;
      final hasData = state.status == DepartureViewStatus.ready;
      emit(
        state.copyWith(
          status: hasData ? DepartureViewStatus.ready : DepartureViewStatus.failure,
          isStale: hasData,
          failure: failure.reason,
        ),
      );
    }
  }

  void _onDeparturesChanged(List<GuideDeparture> departures) {
    final updated = departures.where((departure) => departure.id == _departureId).firstOrNull;
    if (isClosed || updated == null) return;
    emit(
      state.copyWith(
        departure: updated,
        canRequestCompletion: updated.canRequestCompletionAt(_now()),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
