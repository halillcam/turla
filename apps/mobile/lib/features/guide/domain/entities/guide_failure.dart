/// Rehber işlemlerinin hata türleri. Sunucu kodları (`raise exception '<kod>'`)
/// repository'de bu değerlere çevrilir.
enum GuideFailureReason {
  network,
  notSignedIn,
  notAllowed,
  departureNotFound,
  departureNotActive,
  departureNotStarted,
  ticketNotFound,
  unknown,
}

class GuideFailure implements Exception {
  const GuideFailure(this.reason, [this.cause]);

  final GuideFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'GuideFailure($reason, $cause)';
}
