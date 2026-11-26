part of 'active_tour_cubit.dart';

enum ActiveTourStatus { loading, ready, failure }

final class ActiveTourState extends Equatable {
  const ActiveTourState({this.status = ActiveTourStatus.loading, this.tour, this.failure});

  final ActiveTourStatus status;
  final ActiveTour? tour;
  final LiveTourFailureReason? failure;

  @override
  List<Object?> get props => [status, tour, failure];
}
