import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/city_choice/domain/repositories/selected_city_repository.dart';
import 'package:turla_mobile/features/city_choice/presentation/cubit/city_choice_cubit.dart';
import 'package:turla_mobile/features/city_choice/presentation/cubit/selected_city_cubit.dart';

import '../../helpers/fixtures.dart';

class _MockCityRepository extends Mock implements CityRepository {}

class _MockSelectedCityRepository extends Mock implements SelectedCityRepository {}

void main() {
  group('CityChoiceState arama', () {
    const state = CityChoiceState(
      status: CityChoiceStatus.ready,
      cities: [
        City(id: 34, name: 'İstanbul'),
        City(id: 63, name: 'Şanlıurfa'),
        maras,
      ],
    );

    test('Türkçe harf ve büyük/küçük harf farkı yok sayılır', () {
      expect(state.copyWith(query: 'istanbul').visibleCities.single.id, 34);
      expect(state.copyWith(query: 'ISTANBUL').visibleCities.single.id, 34);
      expect(state.copyWith(query: 'sanliurfa').visibleCities.single.id, 63);
      expect(state.copyWith(query: 'maraş').visibleCities.single.id, 46);
    });

    test('boş aramada tüm iller görünür', () {
      expect(state.visibleCities.length, 3);
    });
  });

  group('SelectedCityCubit', () {
    late _MockCityRepository cities;
    late _MockSelectedCityRepository selection;

    setUp(() {
      cities = _MockCityRepository();
      selection = _MockSelectedCityRepository();
      when(() => cities.getCities()).thenAnswer((_) async => [istanbul, maras]);
      when(() => selection.saveSelectedCityId(any())).thenAnswer((_) async {});
    });

    SelectedCityCubit build() =>
        SelectedCityCubit(selectedCityRepository: selection, cityRepository: cities);

    blocTest<SelectedCityCubit, SelectedCityState>(
      'cihazda kayıtlı il yüklenir',
      build: () {
        when(() => selection.readSelectedCityId()).thenAnswer((_) async => 46);
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [const SelectedCityState.ready(cityId: 46, city: maras)],
    );

    blocTest<SelectedCityCubit, SelectedCityState>(
      'cihazda seçim yoksa profildeki il kullanılır',
      build: build,
      seed: () => const SelectedCityState.ready(),
      act: (cubit) => cubit.adoptFromProfile(profileWith(UserRole.customer, selectedCityId: 34)),
      expect: () => [const SelectedCityState.ready(cityId: 34, city: istanbul)],
      verify: (_) => verify(() => selection.saveSelectedCityId(34)).called(1),
    );

    blocTest<SelectedCityCubit, SelectedCityState>(
      'cihazda seçim varsa profil onu ezmez',
      build: build,
      seed: () => const SelectedCityState.ready(cityId: 46, city: maras),
      act: (cubit) => cubit.adoptFromProfile(profileWith(UserRole.customer, selectedCityId: 34)),
      expect: () => <SelectedCityState>[],
    );
  });
}
