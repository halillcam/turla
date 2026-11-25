import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/guide_departure.dart';
import '../../domain/entities/guide_failure.dart';
import '../../domain/repositories/guide_repository.dart';

part 'guide_home_state.dart';

/// Rehberin ana ekranı: atanmış kalkışlar. Önce cihazdaki liste gösterilir,
/// sonra sunucudan tek istekle (`guide_departures`) yenilenir.
class GuideHomeCubit extends Cubit<GuideHomeState> {
  GuideHomeCubit(this._repository, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now,
      super(GuideHomeState(now: (clock ?? DateTime.now)())) {
    _subscription = _repository.departureChanges.listen((departures) {
      if (!isClosed) emit(state.copyWith(departures: departures, now: _now()));
    });
  }

  final GuideRepository _repository;
  final DateTime Function() _now;
  late final StreamSubscription<List<GuideDeparture>> _subscription;

  Future<void> load() async {
    final cached = await _repository.getCachedDepartures();
    if (isClosed) return;
    if (cached != null) {
      emit(state.copyWith(status: GuideHomeStatus.refreshing, departures: cached, now: _now()));
    }
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final departures = await _repository.refreshDepartures();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: GuideHomeStatus.ready,
          departures: departures,
          isStale: false,
          now: _now(),
        ),
      );
    } on GuideFailure catch (failure) {
      if (isClosed) return;
      final hasData =
          state.status == GuideHomeStatus.refreshing || state.status == GuideHomeStatus.ready;
      emit(
        state.copyWith(
          status: hasData ? GuideHomeStatus.ready : GuideHomeStatus.failure,
          isStale: hasData,
          failure: failure.reason,
          now: _now(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
