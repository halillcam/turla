import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/panel_guard.dart';
import '../../domain/entities/departure.dart';
import '../../domain/entities/managed_tour.dart';
import '../../domain/entities/program_day.dart';
import '../../domain/repositories/tour_admin_repository.dart';
import '../models/tour_admin_models.dart';

class TourAdminRepositoryImpl implements TourAdminRepository {
  TourAdminRepositoryImpl(this._client, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const String imageBucket = 'tour-images';
  static const String _jpegMime = 'image/jpeg';

  final SupabaseClient _client;
  final DateTime Function() _clock;

  StorageFileApi get _images => _client.storage.from(imageBucket);

  // ─── Turlar ──────────────────────────────────────────────────────────────

  @override
  Future<List<ManagedTour>> listTours(String companyId) => guardPanel(() async {
    final rows = await _client
        .from(ManagedTourModel.table)
        .select(ManagedTourModel.listColumns)
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return rows.map(ManagedTourModel.fromRow).toList();
  });

  @override
  Future<ManagedTour> getTour(String tourId) => guardPanel(() async {
    final row = await _client
        .from(ManagedTourModel.table)
        .select(ManagedTourModel.columns)
        .eq('id', tourId)
        .single();
    return ManagedTourModel.fromRow(row);
  });

  @override
  Future<ManagedTour> createTour(String companyId, TourDraft draft) => guardPanel(() async {
    final row = await _client
        .from(ManagedTourModel.table)
        .insert({...ManagedTourModel.toRow(draft), 'company_id': companyId})
        .select(ManagedTourModel.columns)
        .single();
    return ManagedTourModel.fromRow(row);
  });

  @override
  Future<ManagedTour> updateTour(String tourId, TourDraft draft) => guardPanel(() async {
    final row = await _client
        .from(ManagedTourModel.table)
        .update(ManagedTourModel.toRow(draft))
        .eq('id', tourId)
        .select(ManagedTourModel.columns)
        .single();
    return ManagedTourModel.fromRow(row);
  });

  @override
  Future<void> setTourActive(String tourId, {required bool isActive}) => guardPanel(() async {
    await _client.from(ManagedTourModel.table).update({'is_active': isActive}).eq('id', tourId);
  });

  @override
  Future<void> deleteTour(String tourId) => guardPanel(() async {
    final tour = await getTour(tourId);
    await _client.from(ManagedTourModel.table).delete().eq('id', tourId);
    await _removeImage(tour);
  });

  // ─── Görsel ──────────────────────────────────────────────────────────────

  @override
  Future<ManagedTour> uploadTourImage(ManagedTour tour, Uint8List jpegBytes) =>
      guardPanel(() async {
        final path = imagePath(tour.companyId, tour.id, _clock());
        await _images.uploadBinary(
          path,
          jpegBytes,
          fileOptions: const FileOptions(contentType: _jpegMime),
        );
        final url = _images.getPublicUrl(path);
        final row = await _client
            .from(ManagedTourModel.table)
            .update({'image_url': url})
            .eq('id', tour.id)
            .select(ManagedTourModel.columns)
            .single();
        await _removeImage(tour);
        return ManagedTourModel.fromRow(row);
      });

  /// `<company_id>/<tour_id>-<zaman>.jpg` — RLS ilk klasörün şirket olmasını ister.
  static String imagePath(String companyId, String tourId, DateTime now) =>
      '$companyId/$tourId-${now.millisecondsSinceEpoch}.jpg';

  /// Public URL'den depolama yolunu çıkarır; bu bucket'a ait değilse null.
  static String? storagePathFromUrl(String? url) {
    if (url == null) return null;
    const marker = '/$imageBucket/';
    final index = url.indexOf(marker);
    if (index < 0) return null;
    final path = Uri.decodeComponent(url.substring(index + marker.length).split('?').first);
    return path.isEmpty ? null : path;
  }

  /// Eski görseli siler (ücretsiz plan depolamasını doldurmamak için).
  /// Silinemezse işlem başarısız sayılmaz.
  Future<void> _removeImage(ManagedTour tour) async {
    final path = storagePathFromUrl(tour.imageUrl);
    if (path == null || !path.startsWith('${tour.companyId}/')) return;
    try {
      await _images.remove([path]);
    } on StorageException {
      // Görsel zaten silinmiş olabilir.
    }
  }

  // ─── Program ─────────────────────────────────────────────────────────────

  @override
  Future<List<ProgramDay>> getProgram(String tourId) => guardPanel(() async {
    final rows = await _client
        .from(ProgramDayModel.table)
        .select(ProgramDayModel.columns)
        .eq('tour_id', tourId)
        .order('day_no');
    return rows.map(ProgramDayModel.fromRow).toList();
  });

  @override
  Future<List<ProgramDay>> saveProgram(String tourId, List<ProgramDay> days) =>
      guardPanel(() async {
        final rows = await _client.rpc<List<dynamic>>(
          'save_tour_program',
          params: {'p_tour_id': tourId, 'p_days': days.map(ProgramDayModel.toJson).toList()},
        );
        final saved = [for (final row in rows) row as Map<String, dynamic>]
          ..sort((a, b) => (a['day_no'] as num).compareTo(b['day_no'] as num));
        return saved.map(ProgramDayModel.fromRow).toList();
      });

  // ─── Tarihler ────────────────────────────────────────────────────────────

  @override
  Future<List<Departure>> listDepartures(String tourId) => guardPanel(() async {
    final rows = await _client
        .from(DepartureModel.table)
        .select(DepartureModel.columns)
        .eq('tour_id', tourId)
        .order('departure_at');
    return rows.map(DepartureModel.fromRow).toList();
  });

  @override
  Future<Departure> createDeparture(String tourId, DepartureDraft draft) => guardPanel(() async {
    final row = await _client
        .from(DepartureModel.table)
        .insert({...DepartureModel.toRow(draft), 'tour_id': tourId})
        .select(DepartureModel.columns)
        .single();
    return DepartureModel.fromRow(row);
  });

  @override
  Future<Departure> updateDeparture(String departureId, DepartureDraft draft) =>
      guardPanel(() async {
        final row = await _client
            .from(DepartureModel.table)
            .update(DepartureModel.toRow(draft))
            .eq('id', departureId)
            .select(DepartureModel.columns)
            .single();
        return DepartureModel.fromRow(row);
      });

  @override
  Future<void> deleteDeparture(String departureId) => guardPanel(() async {
    await _client.from(DepartureModel.table).delete().eq('id', departureId);
  });
}
