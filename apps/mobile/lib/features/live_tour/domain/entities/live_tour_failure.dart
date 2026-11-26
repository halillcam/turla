/// Aktif tur, sohbet ve duyuru işlemlerinin hata türleri. Sunucu kodları
/// (`raise exception '<kod>'`) repository'de bu değerlere çevrilir.
enum LiveTourFailureReason {
  network,
  notSignedIn,
  notAllowed,
  departureNotActive,
  rateLimited,
  messageTooLong,
  unknown,
}

class LiveTourFailure implements Exception {
  const LiveTourFailure(this.reason, [this.cause]);

  final LiveTourFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'LiveTourFailure($reason, $cause)';
}
