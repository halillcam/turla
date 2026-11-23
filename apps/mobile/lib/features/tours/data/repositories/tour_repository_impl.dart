import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_failure.dart';
import '../../domain/repositories/tour_repository.dart';
import '../datasources/tour_local_data_source.dart';
import '../datasources/tour_remote_data_source.dart';

class TourRepositoryImpl implements TourRepository {
  TourRepositoryImpl({
    required TourRemoteDataSource remoteDataSource,
    required TourLocalDataSource localDataSource,
    DateTime Function()? clock,
  }) : _remote = remoteDataSource,
       _local = localDataSource,
       _now = clock ?? DateTime.now;

  final TourRemoteDataSource _remote;
  final TourLocalDataSource _local;
  final DateTime Function() _now;

  @override
  Future<TourListResult> getToursByCity(int cityId, {bool forceRefresh = false}) async {
    final cached = await _readCacheSafely(cityId);

    if (!forceRefresh && cached != null && _isFresh(cached)) {
      return TourListResult(tours: _upcoming(cached.tours));
    }

    try {
      final tours = await _remote.fetchToursByCity(cityId);
      await _writeCacheSafely(cityId, tours);
      return TourListResult(tours: tours);
    } on TourFailure {
      if (cached != null) return TourListResult(tours: _upcoming(cached.tours), isStale: true);
      rethrow;
    } on Object catch (error) {
      if (cached != null) return TourListResult(tours: _upcoming(cached.tours), isStale: true);
      throw TourFailure(_reasonOf(error), error);
    }
  }

  @override
  Future<Tour> getTourDetail(String tourId) async {
    final Tour? tour;
    try {
      tour = await _remote.fetchTourDetail(tourId);
    } on Object catch (error) {
      throw TourFailure(_reasonOf(error), error);
    }
    if (tour == null) throw const TourFailure(TourFailureReason.notFound);
    return tour;
  }

  bool _isFresh(CachedTourList cached) =>
      _now().difference(cached.savedAt) < AppDurations.tourCacheTtl;

  /// Önbellek eskiyse geçmiş kalkışlar ve kalkışı kalmayan turlar çıkarılır.
  List<Tour> _upcoming(List<Tour> tours) {
    final now = _now();
    return tours
        .map((tour) => tour.withDeparturesAfter(now))
        .where((tour) => tour.departures.isNotEmpty)
        .toList();
  }

  Future<CachedTourList?> _readCacheSafely(int cityId) async {
    try {
      return await _local.read(cityId);
    } on Object {
      return null;
    }
  }

  Future<void> _writeCacheSafely(int cityId, List<Tour> tours) async {
    try {
      await _local.write(cityId, tours);
    } on Object {
      // Önbelleğe yazılamaması listeyi göstermeyi engellemez.
    }
  }

  TourFailureReason _reasonOf(Object error) => switch (error) {
    ClientException() || TimeoutException() => TourFailureReason.network,
    _ => TourFailureReason.unknown,
  };
}
