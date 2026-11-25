part of 'guide_home_cubit.dart';

enum GuideHomeStatus { loading, refreshing, ready, failure }

final class GuideHomeState extends Equatable {
  const GuideHomeState({
    required this.now,
    this.status = GuideHomeStatus.loading,
    this.departures = const [],
    this.isStale = false,
    this.failure,
  });

  final GuideHomeStatus status;
  final List<GuideDeparture> departures;

  /// İnternet yokken cihazdaki eski liste gösteriliyor.
  final bool isStale;
  final GuideFailureReason? failure;

  /// Bölümlemede kullanılan "şimdi" (testte sabitlenir).
  final DateTime now;

  /// Bugün kalkan veya kalkış saati geçmiş ama henüz kapanmamış tarihler (en üstte).
  List<GuideDeparture> get todayDepartures => departures
      .where((departure) => !departure.isCompleted && !_isAfterToday(departure.departureAt))
      .toList();

  /// Bugünden sonraki planlanmış tarihler.
  List<GuideDeparture> get upcomingDepartures => departures
      .where((departure) => !departure.isCompleted && _isAfterToday(departure.departureAt))
      .toList();

  /// Son günlerde firma onayıyla kapanan tarihler.
  List<GuideDeparture> get completedDepartures =>
      departures.where((departure) => departure.isCompleted).toList();

  bool get isEmpty => departures.isEmpty;

  bool _isAfterToday(DateTime at) {
    final local = at.toLocal();
    final today = now.toLocal();
    final endOfToday = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
    return !local.isBefore(endOfToday);
  }

  GuideHomeState copyWith({
    GuideHomeStatus? status,
    List<GuideDeparture>? departures,
    bool? isStale,
    GuideFailureReason? failure,
    DateTime? now,
  }) => GuideHomeState(
    status: status ?? this.status,
    departures: departures ?? this.departures,
    isStale: isStale ?? this.isStale,
    failure: failure,
    now: now ?? this.now,
  );

  @override
  List<Object?> get props => [status, departures, isStale, failure, now];
}
