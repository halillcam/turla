part of 'city_choice_cubit.dart';

enum CityChoiceStatus { initial, loading, ready, failure }

final class CityChoiceState extends Equatable {
  const CityChoiceState({
    this.status = CityChoiceStatus.initial,
    this.cities = const [],
    this.query = '',
  });

  final CityChoiceStatus status;
  final List<City> cities;
  final String query;

  /// Aramaya uyan iller (Türkçe harf farkı yok sayılır).
  List<City> get visibleCities =>
      cities.where((city) => SearchNormalizer.matches(city.name, query)).toList();

  CityChoiceState copyWith({CityChoiceStatus? status, List<City>? cities, String? query}) =>
      CityChoiceState(
        status: status ?? this.status,
        cities: cities ?? this.cities,
        query: query ?? this.query,
      );

  @override
  List<Object?> get props => [status, cities, query];
}
