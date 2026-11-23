import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/utils/search_normalizer.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_failure.dart';
import '../../domain/repositories/tour_repository.dart';

part 'tour_list_state.dart';

/// Seçili ilden kalkan turlar. Turlar bölgelere göre gruplanır ve aranabilir.
class TourListCubit extends Cubit<TourListState> {
  TourListCubit(this._tourRepository) : super(const TourListState());

  final TourRepository _tourRepository;

  Future<void> load(int cityId) => _fetch(cityId, forceRefresh: false);

  Future<void> refresh() async {
    final cityId = state.cityId;
    if (cityId != null) await _fetch(cityId, forceRefresh: true);
  }

  void search(String query) => emit(state.copyWith(query: query));

  Future<void> _fetch(int cityId, {required bool forceRefresh}) async {
    final isSameCity = state.cityId == cityId && state.tours.isNotEmpty;
    emit(
      state.copyWith(
        cityId: cityId,
        status: isSameCity ? TourListStatus.refreshing : TourListStatus.loading,
        tours: isSameCity ? state.tours : const [],
      ),
    );
    try {
      final result = await _tourRepository.getToursByCity(cityId, forceRefresh: forceRefresh);
      emit(
        state.copyWith(status: TourListStatus.ready, tours: result.tours, isStale: result.isStale),
      );
    } on TourFailure catch (failure) {
      emit(state.copyWith(status: TourListStatus.failure, failure: failure.reason));
    }
  }
}
