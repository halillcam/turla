import '../constants/core_strings.dart';

/// Veritabanındaki `tour_region` tipinin karşılığı.
enum TourRegion {
  mediterranean('akdeniz', CoreStrings.regionMediterranean),
  blackSea('karadeniz', CoreStrings.regionBlackSea),
  marmara('marmara', CoreStrings.regionMarmara),
  aegean('ege', CoreStrings.regionAegean),
  centralAnatolia('ic_anadolu', CoreStrings.regionCentralAnatolia),
  easternAnatolia('dogu_anadolu', CoreStrings.regionEasternAnatolia),
  southeasternAnatolia('guneydogu_anadolu', CoreStrings.regionSoutheasternAnatolia),
  dayTrip('gunubirlik', CoreStrings.regionDayTrip),
  abroad('yurtdisi', CoreStrings.regionAbroad);

  const TourRegion(this.value, this.label);

  final String value;
  final String label;

  static TourRegion fromValue(String value) => TourRegion.values.firstWhere(
    (region) => region.value == value,
    orElse: () => TourRegion.dayTrip,
  );
}
