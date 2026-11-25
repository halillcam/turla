part of 'tour_list_cubit.dart';

enum TourListStatus { initial, loading, refreshing, ready, failure }

/// Bir bölgenin başlığı altında gösterilecek turlar.
class RegionSection extends Equatable {
  const RegionSection({required this.region, required this.tours});

  final TourRegion region;
  final List<Tour> tours;

  @override
  List<Object?> get props => [region, tours];
}

final class TourListState extends Equatable {
  const TourListState({
    this.status = TourListStatus.initial,
    this.cityId,
    this.tours = const [],
    this.query = '',
    this.region,
    this.isStale = false,
    this.failure,
  });

  final TourListStatus status;
  final int? cityId;
  final List<Tour> tours;
  final String query;

  /// Doluysa sadece bu bölgenin turları gösterilir ("Tümünü gör" ekranı).
  final TourRegion? region;

  /// İnternet yokken önbellekteki eski liste gösteriliyor.
  final bool isStale;
  final TourFailureReason? failure;

  bool get isLoading => status == TourListStatus.initial || status == TourListStatus.loading;

  /// Aramaya uyan turlar, bölge sırasına göre gruplanmış. Boş bölgeler çıkarılır.
  List<RegionSection> get sections {
    final visible = tours
        .where(
          (tour) =>
              SearchNormalizer.matches(tour.title, query) ||
              SearchNormalizer.matches(tour.companyName, query),
        )
        .toList();

    final sections = <RegionSection>[];
    final onlyRegion = region;
    for (final region in TourRegion.values) {
      if (onlyRegion != null && region != onlyRegion) continue;
      final regionTours = visible.where((tour) => tour.region == region).toList();
      if (regionTours.isNotEmpty) {
        sections.add(RegionSection(region: region, tours: regionTours));
      }
    }
    return sections;
  }

  /// Seçili bölgenin (veya tüm bölgelerin) turları, tek dikey liste için.
  List<Tour> get visibleTours => [for (final section in sections) ...section.tours];

  TourListState copyWith({
    TourListStatus? status,
    int? cityId,
    List<Tour>? tours,
    String? query,
    TourRegion? region,
    bool? isStale,
    TourFailureReason? failure,
  }) => TourListState(
    status: status ?? this.status,
    cityId: cityId ?? this.cityId,
    tours: tours ?? this.tours,
    query: query ?? this.query,
    region: region ?? this.region,
    isStale: isStale ?? this.isStale,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, cityId, tours, query, region, isStale, failure];
}
