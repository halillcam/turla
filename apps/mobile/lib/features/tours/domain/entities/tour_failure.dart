enum TourFailureReason { network, notFound, unknown }

class TourFailure implements Exception {
  const TourFailure(this.reason, [this.cause]);

  final TourFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'TourFailure($reason, $cause)';
}
