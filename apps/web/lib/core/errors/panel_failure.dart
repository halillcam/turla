/// Panel işlemlerinde oluşabilecek hata türleri. Sunucudaki fonksiyonların
/// döndürdüğü sabit kodlar (`raise exception 'kod'`) ve Edge Function kodları
/// buraya çevrilir; arayüz bunu kullanıcı mesajına dönüştürür.
enum PanelFailureReason {
  network,
  notAllowed,
  notFound,
  companyInactive,
  hasTickets,
  capacityBelowSoldSeats,
  invalidGuide,
  alreadyReviewed,
  emailExists,
  weakPassword,
  invalidInput,
  cannotChangeSelf,
  invalidImage,
  unknown,
}

class PanelFailure implements Exception {
  const PanelFailure(this.reason, [this.cause]);

  final PanelFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'PanelFailure($reason, $cause)';
}
