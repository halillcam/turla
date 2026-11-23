import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/utils/search_normalizer.dart';

part 'city_choice_state.dart';

/// Şehir seçimi ekranı: il listesini yükler ve aramaya göre süzer.
class CityChoiceCubit extends Cubit<CityChoiceState> {
  CityChoiceCubit(this._cityRepository) : super(const CityChoiceState());

  final CityRepository _cityRepository;

  Future<void> load() async {
    emit(state.copyWith(status: CityChoiceStatus.loading));
    try {
      final cities = await _cityRepository.getCities();
      emit(state.copyWith(status: CityChoiceStatus.ready, cities: cities));
    } on CitiesUnavailableException {
      emit(state.copyWith(status: CityChoiceStatus.failure));
    }
  }

  void search(String query) => emit(state.copyWith(query: query));
}
