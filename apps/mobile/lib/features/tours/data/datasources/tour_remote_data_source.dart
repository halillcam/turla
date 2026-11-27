import 'package:turla_core/turla_core.dart';

import '../../domain/entities/tour.dart';
import '../models/tour_model.dart';

abstract interface class TourRemoteDataSource {
  Future<List<Tour>> fetchToursByCity(int cityId);

  /// Tur yoksa veya yayından kalktıysa null.
  Future<Tour?> fetchTourDetail(String tourId);
}

class TourRemoteDataSourceImpl implements TourRemoteDataSource {
  const TourRemoteDataSourceImpl(this._client);

  static const String _table = 'tours';
  static const String _departures = 'departures';
  static const String _program = 'program';
  static const String _scheduled = 'scheduled';

  final SupabaseClient _client;

  @override
  Future<List<Tour>> fetchToursByCity(int cityId) async {
    final rows = await _client
        .from(_table)
        .select(TourModel.listColumns)
        .eq('city_id', cityId)
        .eq('is_active', true)
        .eq('$_departures.status', _scheduled)
        .gt('$_departures.departure_at', _nowIso())
        .order('departure_at', referencedTable: _departures, ascending: true)
        .order('title', ascending: true);

    return rows
        .map(TourModel.fromRow)
        // Yaklaşan tarihi olmayan tur listede gösterilmez.
        .where((tour) => tour.departures.isNotEmpty)
        .toList();
  }

  @override
  Future<Tour?> fetchTourDetail(String tourId) async {
    final row = await _client
        .from(_table)
        .select(TourModel.detailColumns)
        .eq('id', tourId)
        .eq('is_active', true)
        .eq('$_departures.status', _scheduled)
        .gt('$_departures.departure_at', _nowIso())
        .order('departure_at', referencedTable: _departures, ascending: true)
        .order('day_no', referencedTable: _program, ascending: true)
        .maybeSingle();
    return row == null ? null : TourModel.fromRow(row);
  }

  String _nowIso() => DateTime.now().toUtc().toIso8601String();
}
