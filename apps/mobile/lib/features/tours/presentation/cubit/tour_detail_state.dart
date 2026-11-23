part of 'tour_detail_cubit.dart';

enum TourDetailStatus { loading, ready, failure }

final class TourDetailState extends Equatable {
  const TourDetailState({this.status = TourDetailStatus.loading, this.tour, this.failure});

  final TourDetailStatus status;
  final Tour? tour;
  final TourFailureReason? failure;

  @override
  List<Object?> get props => [status, tour, failure];
}
