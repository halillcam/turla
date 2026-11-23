part of 'selected_city_cubit.dart';

final class SelectedCityState extends Equatable {
  const SelectedCityState._({required this.isLoading, this.cityId, this.city});

  const SelectedCityState.loading() : this._(isLoading: true);

  /// [city] ilin adıdır; il listesi henüz alınamadıysa null olabilir.
  const SelectedCityState.ready({int? cityId, City? city})
    : this._(isLoading: false, cityId: cityId, city: city);

  final bool isLoading;
  final int? cityId;
  final City? city;

  bool get hasCity => cityId != null;

  @override
  List<Object?> get props => [isLoading, cityId, city];
}
