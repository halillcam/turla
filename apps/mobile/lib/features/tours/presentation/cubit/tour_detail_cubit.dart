import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tour.dart';
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
      emit(TourDetailState(status: TourDetailStatus.ready, tour: tour));
    } on TourFailure catch (failure) {
      emit(TourDetailState(status: TourDetailStatus.failure, failure: failure.reason));
    }
  }
}
