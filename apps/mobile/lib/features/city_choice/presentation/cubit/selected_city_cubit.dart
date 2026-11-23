import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/repositories/selected_city_repository.dart';

part 'selected_city_state.dart';

/// Uygulama genelinde seçili il. Router bu duruma bakarak ilk açılışta
/// şehir seçimi ekranını gösterir.
class SelectedCityCubit extends Cubit<SelectedCityState> {
  SelectedCityCubit({
    required SelectedCityRepository selectedCityRepository,
    required CityRepository cityRepository,
  }) : _selection = selectedCityRepository,
       _cities = cityRepository,
       super(const SelectedCityState.loading());

  final SelectedCityRepository _selection;
  final CityRepository _cities;

  Future<void> load() async {
    final cityId = await _selection.readSelectedCityId();
    emit(SelectedCityState.ready(cityId: cityId, city: await _resolve(cityId)));
  }

  Future<void> select(City city) async {
    await _selection.saveSelectedCityId(city.id);
    emit(SelectedCityState.ready(cityId: city.id, city: city));
  }

  /// Giriş yapan kullanıcının profilinde il varsa ve cihazda seçim yoksa onu kullanır.
  Future<void> adoptFromProfile(UserProfile profile) async {
    final profileCityId = profile.selectedCityId;
    if (state.cityId != null || profileCityId == null) return;
    final city = await _resolve(profileCityId);
    if (city != null) await select(city);
  }

  Future<City?> _resolve(int? cityId) async {
    if (cityId == null) return null;
    try {
      final cities = await _cities.getCities();
      for (final city in cities) {
        if (city.id == cityId) return city;
      }
      return null;
    } on CitiesUnavailableException {
      return null;
    }
  }
}
