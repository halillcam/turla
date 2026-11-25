part of 'tour_detail_cubit.dart';

enum TourDetailStatus { loading, ready, failure }

final class TourDetailState extends Equatable {
  const TourDetailState({
    this.status = TourDetailStatus.loading,
    this.tour,
    this.failure,
    this.selectedDepartureId,
  });

  final TourDetailStatus status;
  final Tour? tour;
  final TourFailureReason? failure;

  /// Bilet alınacak kalkış (dolu tarihler seçilemez).
  final String? selectedDepartureId;

  TourDeparture? get selectedDeparture =>
      tour?.departures.where((departure) => departure.id == selectedDepartureId).firstOrNull;

  /// Seçili tarih varsa ve doluysa bilet alınamaz.
  bool get canBuy => selectedDeparture != null && !selectedDeparture!.isSoldOut;

  @override
  List<Object?> get props => [status, tour, failure, selectedDepartureId];
}
