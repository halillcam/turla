import '../entities/active_tour.dart';

/// Müşterinin aktif tur bilgisi. Canlı veri: her açılışta sunucudan gelir.
/// Hatalar [LiveTourFailure] olarak fırlatılır.
abstract interface class ActiveTourRepository {
  Future<ActiveTour> fetch(String departureId);
}
