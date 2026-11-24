import 'dart:typed_data';

import '../entities/departure.dart';
import '../entities/managed_tour.dart';
import '../entities/program_day.dart';

/// Şirket admininin tur, program, tarih ve görsel işlemleri.
/// Yetki RLS ve sunucu fonksiyonlarıyla denetlenir. Hatalar `PanelFailure`.
abstract interface class TourAdminRepository {
  Future<List<ManagedTour>> listTours(String companyId);

  Future<ManagedTour> getTour(String tourId);

  Future<ManagedTour> createTour(String companyId, TourDraft draft);

  Future<ManagedTour> updateTour(String tourId, TourDraft draft);

  Future<void> setTourActive(String tourId, {required bool isActive});

  /// Satılmış bileti olan tur silinemez (`PanelFailureReason.hasTickets`).
  Future<void> deleteTour(String tourId);

  /// Küçültülmüş JPEG'i `tour-images/<company_id>/` altına yükler, turun
  /// görselini günceller ve eski görseli siler.
  Future<ManagedTour> uploadTourImage(ManagedTour tour, Uint8List jpegBytes);

  Future<List<ProgramDay>> getProgram(String tourId);

  /// Programı tek seferde (atomik) değiştirir.
  Future<List<ProgramDay>> saveProgram(String tourId, List<ProgramDay> days);

  Future<List<Departure>> listDepartures(String tourId);

  Future<Departure> createDeparture(String tourId, DepartureDraft draft);

  Future<Departure> updateDeparture(String departureId, DepartureDraft draft);

  Future<void> deleteDeparture(String departureId);
}
