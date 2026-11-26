import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/active_tour.dart';
import '../../domain/entities/live_tour_failure.dart';
import '../../domain/repositories/active_tour_repository.dart';

part 'active_tour_state.dart';

/// Müşterinin aktif tur ekranı. Canlı veri: açılışta ve aşağı çekince sunucudan gelir.
class ActiveTourCubit extends Cubit<ActiveTourState> {
  ActiveTourCubit(this._repository) : super(const ActiveTourState());

  final ActiveTourRepository _repository;
  String? _departureId;

  Future<void> load(String departureId) async {
    _departureId = departureId;
    emit(ActiveTourState(tour: state.tour));
    await refresh();
  }

  Future<void> refresh() async {
    final departureId = _departureId;
    if (departureId == null) return;
    try {
      final tour = await _repository.fetch(departureId);
      if (isClosed) return;
      emit(ActiveTourState(status: ActiveTourStatus.ready, tour: tour));
    } on LiveTourFailure catch (failure) {
      if (isClosed) return;
      emit(ActiveTourState(status: ActiveTourStatus.failure, tour: state.tour, failure: failure.reason));
    }
  }
}
