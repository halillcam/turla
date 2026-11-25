import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/guide/data/datasources/guide_local_data_source.dart';
import 'package:turla_mobile/features/guide/data/datasources/guide_remote_data_source.dart';
import 'package:turla_mobile/features/guide/data/models/guide_models.dart';
import 'package:turla_mobile/features/guide/data/repositories/guide_repository_impl.dart';
import 'package:turla_mobile/features/guide/domain/entities/check_in_result.dart';
import 'package:turla_mobile/features/guide/domain/entities/guide_departure.dart';
import 'package:turla_mobile/features/guide/domain/entities/guide_failure.dart';
import 'package:turla_mobile/features/guide/domain/entities/participant.dart';

import '../../helpers/guide_fixtures.dart';

class _FakeRemote implements GuideRemoteDataSource {
  List<GuideDeparture> departures = [departureWith(checkedInCount: 0)];
  List<Participant> participants = [
    participantWith(id: 't1', name: 'Ali Veli'),
    participantWith(id: 't2', name: 'Ayşe Kaya'),
  ];
  CheckInResult scanResult = CheckInResult(
    code: CheckInCode.ok,
    ticketId: 't1',
    passengerName: 'Ali Veli',
    scannedAt: DateTime.utc(2026, 11, 26, 5, 10),
  );
  Object? error;
  String? scannedCode;
  int fetchCount = 0;

  void _throwIfNeeded() {
    final error = this.error;
    if (error != null) throw error;
  }

  @override
  String? get currentUserId => 'guide-1';

  @override
  Future<List<GuideDeparture>> fetchDepartures() async {
    _throwIfNeeded();
    fetchCount++;
    return departures;
  }

  @override
  Future<List<Participant>> fetchParticipants(String departureId) async {
    _throwIfNeeded();
    fetchCount++;
    return participants;
  }

  @override
  Future<CheckInResult> scanTicket({required String departureId, required String code}) async {
    _throwIfNeeded();
    scannedCode = code;
    return scanResult;
  }

  @override
  Future<CheckInResult> checkInManually(String ticketId) async {
    _throwIfNeeded();
    return CheckInResult(
      code: CheckInCode.ok,
      ticketId: ticketId,
      passengerName: 'Ayşe Kaya',
      scannedAt: DateTime.utc(2026, 11, 26, 5, 20),
    );
  }

  @override
  Future<void> requestCompletion(String departureId) async => _throwIfNeeded();
}

class _MemoryLocal implements GuideLocalDataSource {
  final Map<String, List<GuideDeparture>> departures = {};
  final Map<String, List<Participant>> participants = {};

  @override
  Future<List<GuideDeparture>?> readDepartures(String userId) async => departures[userId];

  @override
  Future<void> writeDepartures(String userId, List<GuideDeparture> value) async =>
      departures[userId] = value;

  @override
  Future<List<Participant>?> readParticipants(String userId, String departureId) async =>
      participants['$userId.$departureId'];

  @override
  Future<void> writeParticipants(
    String userId,
    String departureId,
    List<Participant> value,
  ) async => participants['$userId.$departureId'] = value;
}

void main() {
  late _FakeRemote remote;
  late _MemoryLocal local;
  late GuideRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    local = _MemoryLocal();
    repository = GuideRepositoryImpl(remoteDataSource: remote, localDataSource: local);
  });

  test('kalkışlar sunucudan gelir, cihaza yazılır ve değişiklik yayılır', () async {
    final emitted = expectLater(repository.departureChanges, emits(remote.departures));
    final departures = await repository.refreshDepartures();
    await emitted;
    expect(departures, remote.departures);
    expect(await repository.getCachedDepartures(), remote.departures);
  });

  test('katılımcılar yenilenince kalkışın sayıları da güncellenir (ek istek yok)', () async {
    remote.participants = [
      participantWith(id: 't1', status: TicketStatus.checkedIn),
      participantWith(id: 't2'),
    ];
    await repository.refreshDepartures();
    await repository.refreshParticipants('dep-1');
    final departure = (await repository.getCachedDepartures())!.single;
    expect(departure.ticketCount, 2);
    expect(departure.checkedInCount, 1);
    expect(remote.fetchCount, 2);
  });

  test('başarılı okutma cihazdaki katılımcıyı ve sayıyı günceller', () async {
    await repository.refreshDepartures();
    await repository.refreshParticipants('dep-1');

    final result = await repository.scanTicket(departureId: 'dep-1', code: '  kod-123 ');

    expect(result.isSuccess, isTrue);
    expect(remote.scannedCode, 'kod-123');
    final participants = (await repository.getCachedParticipants('dep-1'))!;
    final ali = participants.firstWhere((participant) => participant.ticketId == 't1');
    expect(ali.hasArrived, isTrue);
    expect(ali.checkInMethod, CheckInMethod.qr);
    expect(ali.checkedInAt, DateTime.utc(2026, 11, 26, 5, 10));
    expect((await repository.getCachedDepartures())!.single.checkedInCount, 1);
  });

  test('başarısız okutma (daha önce okutuldu) cihazda bir şey değiştirmez', () async {
    remote.scanResult = const CheckInResult(code: CheckInCode.alreadyUsed, ticketId: 't1');
    await repository.refreshDepartures();
    await repository.refreshParticipants('dep-1');

    final result = await repository.scanTicket(departureId: 'dep-1', code: 'kod');

    expect(result.code, CheckInCode.alreadyUsed);
    expect((await repository.getCachedParticipants('dep-1'))!.any((p) => p.hasArrived), isFalse);
    expect((await repository.getCachedDepartures())!.single.checkedInCount, 0);
  });

  test('elle işaretleme kayda "elle" olarak geçer', () async {
    await repository.refreshDepartures();
    await repository.refreshParticipants('dep-1');

    await repository.checkInManually('t2');

    final ayse = (await repository.getCachedParticipants(
      'dep-1',
    ))!.firstWhere((participant) => participant.ticketId == 't2');
    expect(ayse.checkInMethod, CheckInMethod.manual);
    expect((await repository.getCachedDepartures())!.single.checkedInCount, 1);
  });

  test('bitirme talebi sonrası kalkış "onay bekliyor" olur', () async {
    await repository.refreshDepartures();
    await repository.requestCompletion('dep-1');
    final departure = (await repository.getCachedDepartures())!.single;
    expect(departure.status, DepartureStatus.finishRequested);
    expect(departure.isAwaitingApproval, isTrue);
  });

  test('internet yoksa okutma network hatası verir', () async {
    remote.error = ClientException('offline');
    await expectLater(
      repository.scanTicket(departureId: 'dep-1', code: 'kod'),
      throwsA(isA<GuideFailure>().having((f) => f.reason, 'reason', GuideFailureReason.network)),
    );
  });

  test('sunucu hata kodları rehber hata türlerine çevrilir', () async {
    remote.error = const PostgrestException(message: 'departure_not_started', code: 'P0001');
    await expectLater(
      repository.requestCompletion('dep-1'),
      throwsA(
        isA<GuideFailure>().having(
          (f) => f.reason,
          'reason',
          GuideFailureReason.departureNotStarted,
        ),
      ),
    );
    expect(
      GuideErrorMapper.fromPostgrest('P0001', 'departure_not_active'),
      GuideFailureReason.departureNotActive,
    );
    expect(GuideErrorMapper.fromPostgrest('P0001', 'not_allowed'), GuideFailureReason.notAllowed);
    expect(
      GuideErrorMapper.fromPostgrest('P0001', 'ticket_not_found'),
      GuideFailureReason.ticketNotFound,
    );
    expect(GuideErrorMapper.fromPostgrest('42501', 'x'), GuideFailureReason.notAllowed);
    expect(GuideErrorMapper.fromPostgrest(null, 'x'), GuideFailureReason.unknown);
  });

  test('model: guide_departures satırı ve önbellek biçimi aynen geri okunur', () {
    final row = {
      'id': 'dep-1',
      'tour_id': 'tour-1',
      'tour_title': 'Yerköprü',
      'company_name': 'Demo',
      'departure_at': '2026-11-26T05:30:00+00:00',
      'status': 'finish_requested',
      'capacity': 25,
      'bus_plate': null,
      'driver_name': null,
      'driver_phone': null,
      'ticket_count': 4,
      'checked_in_count': 2,
      'last_request_status': 'pending',
    };
    final departure = GuideDepartureModel.fromRow(row);
    expect(departure.isAwaitingApproval, isTrue);
    expect(departure.lastRequestStatus, CompletionRequestStatus.pending);
    expect(departure.notArrivedCount, 2);
    expect(GuideDepartureModel.fromRow(GuideDepartureModel.toRow(departure)), departure);

    final participant = participantWith(
      status: TicketStatus.checkedIn,
      checkedInAt: DateTime.utc(2026, 11, 26, 5),
      method: CheckInMethod.manual,
    );
    expect(ParticipantModel.fromRow(ParticipantModel.toRow(participant)), participant);

    final result = CheckInResultModel.fromJson({'ok': false, 'code': 'wrong_departure'});
    expect(result.code, CheckInCode.wrongDeparture);
    expect(CheckInCode.fromValue('bilinmeyen'), CheckInCode.notFound);
  });
}
