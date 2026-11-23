import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:turla_mobile/features/tours/data/datasources/tour_local_data_source.dart';
import 'package:turla_mobile/features/tours/data/datasources/tour_remote_data_source.dart';
import 'package:turla_mobile/features/tours/data/repositories/tour_repository_impl.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour_failure.dart';

import '../../helpers/fixtures.dart';

class _FakeRemote implements TourRemoteDataSource {
  List<Tour> tours = [tourWith()];
  Tour? detail;
  Object? error;
  int listCalls = 0;

  @override
  Future<List<Tour>> fetchToursByCity(int cityId) async {
    listCalls++;
    if (error != null) throw error!;
    return tours;
  }

  @override
  Future<Tour?> fetchTourDetail(String tourId) async {
    if (error != null) throw error!;
    return detail;
  }
}

class _FakeLocal implements TourLocalDataSource {
  CachedTourList? cached;
  List<Tour>? written;

  @override
  Future<CachedTourList?> read(int cityId) async => cached;

  @override
  Future<void> write(int cityId, List<Tour> tours) async => written = tours;
}

void main() {
  final now = DateTime.utc(2026, 12, 1, 12);
  late _FakeRemote remote;
  late _FakeLocal local;
  late TourRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repository = TourRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      clock: () => now,
    );
  });

  test('önbellek yoksa sunucudan çeker ve kaydeder', () async {
    final result = await repository.getToursByCity(46);

    expect(result.tours.length, 1);
    expect(result.isStale, isFalse);
    expect(remote.listCalls, 1);
    expect(local.written, isNotNull);
  });

  test('önbellek 20 dakikadan yeniyse sunucuya gidilmez', () async {
    local.cached = CachedTourList(
      tours: [tourWith(title: 'Önbellekteki')],
      savedAt: now.subtract(const Duration(minutes: 5)),
    );

    final result = await repository.getToursByCity(46);

    expect(remote.listCalls, 0);
    expect(result.tours.single.title, 'Önbellekteki');
  });

  test('önbellek eskiyse sunucudan yenilenir', () async {
    local.cached = CachedTourList(
      tours: [tourWith(title: 'Eski')],
      savedAt: now.subtract(const Duration(hours: 1)),
    );

    final result = await repository.getToursByCity(46);

    expect(remote.listCalls, 1);
    expect(result.tours.single.title, 'Kapadokya Turu');
  });

  test('internet yoksa eski önbellek "eski veri" işaretiyle döner', () async {
    local.cached = CachedTourList(
      tours: [tourWith(title: 'Eski')],
      savedAt: now.subtract(const Duration(hours: 1)),
    );
    remote.error = ClientException('bağlantı yok');

    final result = await repository.getToursByCity(46);

    expect(result.isStale, isTrue);
    expect(result.tours.single.title, 'Eski');
  });

  test('önbellekten okurken geçmiş kalkışlar ve kalkışı kalmayan turlar çıkarılır', () async {
    local.cached = CachedTourList(
      tours: [
        tourWith(
          id: 'a',
          departures: [now.subtract(const Duration(days: 1)), now.add(const Duration(days: 2))],
        ),
        tourWith(id: 'b', departures: [now.subtract(const Duration(days: 3))]),
      ],
      savedAt: now.subtract(const Duration(minutes: 1)),
    );

    final result = await repository.getToursByCity(46);

    expect(result.tours.map((tour) => tour.id), ['a']);
    expect(result.tours.single.departures.length, 1);
  });

  test('ne önbellek ne internet varsa ağ hatası fırlatır', () async {
    remote.error = ClientException('bağlantı yok');

    expect(
      repository.getToursByCity(46),
      throwsA(isA<TourFailure>().having((f) => f.reason, 'reason', TourFailureReason.network)),
    );
  });

  test('yayında olmayan tur detayı "bulunamadı" hatası verir', () async {
    remote.detail = null;

    expect(
      repository.getTourDetail('yok'),
      throwsA(isA<TourFailure>().having((f) => f.reason, 'reason', TourFailureReason.notFound)),
    );
  });
}
