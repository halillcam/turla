import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_departure.dart';
import '../../domain/entities/tour_failure.dart';
import '../../domain/repositories/tour_repository.dart';

part 'tour_detail_state.dart';

class TourDetailCubit extends Cubit<TourDetailState> {
  TourDetailCubit(this._tourRepository) : super(const TourDetailState());

  final TourRepository _tourRepository;

  Future<void> load(String tourId) async {
    emit(const TourDetailState(status: TourDetailStatus.loading));
    try {
      final tour = await _tourRepository.getTourDetail(tourId);
      if (isClosed) return;
      // Varsayılan seçim: boş koltuğu olan en yakın tarih.
      final firstAvailable = tour.departures.where((departure) => !departure.isSoldOut).firstOrNull;
      emit(
        TourDetailState(
          status: TourDetailStatus.ready,
          tour: tour,
          selectedDepartureId: firstAvailable?.id,
        ),
      );
    } on TourFailure catch (failure) {
      if (isClosed) return;
      emit(TourDetailState(status: TourDetailStatus.failure, failure: failure.reason));
    }
  }

  void selectDeparture(String departureId) {
    final tour = state.tour;
    final departure = tour?.departures.where((item) => item.id == departureId).firstOrNull;
    if (departure == null || departure.isSoldOut) return;
    emit(TourDetailState(status: state.status, tour: tour, selectedDepartureId: departureId));
  }
}
