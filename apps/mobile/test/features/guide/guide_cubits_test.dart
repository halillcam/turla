import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/guide/domain/entities/check_in_result.dart';
import 'package:turla_mobile/features/guide/domain/entities/guide_departure.dart';
import 'package:turla_mobile/features/guide/domain/entities/guide_failure.dart';
import 'package:turla_mobile/features/guide/domain/entities/participant.dart';
import 'package:turla_mobile/features/guide/domain/repositories/guide_repository.dart';
import 'package:turla_mobile/features/guide/presentation/cubit/departure_cubit.dart';
import 'package:turla_mobile/features/guide/presentation/cubit/guide_home_cubit.dart';
import 'package:turla_mobile/features/guide/presentation/cubit/scan_cubit.dart';
import 'package:turla_mobile/features/guide/presentation/utils/guide_display.dart';

import '../../helpers/guide_fixtures.dart';

class _MockGuideRepository extends Mock implements GuideRepository {}

void main() {
  late _MockGuideRepository repository;
  late StreamController<List<GuideDeparture>> changes;

  setUpAll(() => initializeDateFormatting('tr_TR'));

  setUp(() {
    repository = _MockGuideRepository();
    changes = StreamController.broadcast();
    when(() => repository.departureChanges).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  group('GuideHomeState bölümleri', () {
    // Yerel saatten bağımsız olsun diye "şimdi" yerel saatle kurulur.
    final now = DateTime(2026, 11, 26, 9);
    final overdue = departureWith(id: 'overdue', departureAt: DateTime(2026, 11, 25, 8));
    final today = departureWith(id: 'today', departureAt: DateTime(2026, 11, 26, 20));
    final tomorrow = departureWith(id: 'tomorrow', departureAt: DateTime(2026, 11, 27, 0, 30));
    final done = departureWith(
      id: 'done',
      departureAt: DateTime(2026, 11, 25, 8),
      status: DepartureStatus.completed,
    );
    final state = GuideHomeState(now: now, departures: [overdue, today, tomorrow, done]);

    test('bugün: bugünküler ve kapanmamış geçmiş tarih; yaklaşan ve tamamlanan ayrı', () {
      expect(state.todayDepartures.map((d) => d.id), ['overdue', 'today']);
      expect(state.upcomingDepartures.map((d) => d.id), ['tomorrow']);
      expect(state.completedDepartures.map((d) => d.id), ['done']);
    });

    test('durum bandı: onay bekliyor, reddedildi, tamamlandı', () {
      expect(departureWith(status: DepartureStatus.finishRequested).statusBanner, isNotNull);
      final rejected = departureWith(lastRequestStatus: CompletionRequestStatus.rejected);
      expect(rejected.wasRejected, isTrue);
      expect(rejected.statusBanner, isNotNull);
      expect(departureWith().statusBanner, isNull);
    });

    test('turu bitir kalkış saatinden sonra ve sadece açık tarihte', () {
      final departure = departureWith(departureAt: DateTime(2026, 11, 26, 8));
      expect(departure.canRequestCompletionAt(now), isTrue);
      expect(departure.canRequestCompletionAt(DateTime(2026, 11, 26, 7)), isFalse);
      expect(
        departureWith(
          departureAt: DateTime(2026, 11, 26, 8),
          status: DepartureStatus.finishRequested,
        ).canRequestCompletionAt(now),
        isFalse,
      );
    });
  });

  group('GuideHomeCubit', () {
    final clock = DateTime(2026, 11, 26, 9);
    final departures = [departureWith()];

    blocTest<GuideHomeCubit, GuideHomeState>(
      'önce cihazdaki liste, sonra sunucudaki liste',
      build: () {
        when(() => repository.getCachedDepartures()).thenAnswer((_) async => departures);
        when(() => repository.refreshDepartures()).thenAnswer((_) async => departures);
        return GuideHomeCubit(repository, clock: () => clock);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        GuideHomeState(now: clock, status: GuideHomeStatus.refreshing, departures: departures),
        GuideHomeState(now: clock, status: GuideHomeStatus.ready, departures: departures),
      ],
    );

    blocTest<GuideHomeCubit, GuideHomeState>(
      'internet yoksa cihazdaki liste "eski" uyarısıyla kalır',
      build: () {
        when(() => repository.getCachedDepartures()).thenAnswer((_) async => departures);
        when(
          () => repository.refreshDepartures(),
        ).thenThrow(const GuideFailure(GuideFailureReason.network));
        return GuideHomeCubit(repository, clock: () => clock);
      },
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        GuideHomeState(
          now: clock,
          status: GuideHomeStatus.ready,
          departures: departures,
          isStale: true,
          failure: GuideFailureReason.network,
        ),
      ],
    );

    blocTest<GuideHomeCubit, GuideHomeState>(
      'cihazda kayıt yokken internet yoksa hata gösterilir',
      build: () {
        when(() => repository.getCachedDepartures()).thenAnswer((_) async => null);
        when(
          () => repository.refreshDepartures(),
        ).thenThrow(const GuideFailure(GuideFailureReason.network));
        return GuideHomeCubit(repository, clock: () => clock);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        GuideHomeState(
          now: clock,
          status: GuideHomeStatus.failure,
          failure: GuideFailureReason.network,
        ),
      ],
    );
  });

  group('DepartureCubit', () {
    final departure = departureWith(departureAt: DateTime.utc(2026, 11, 26, 5));
    final participants = [
      participantWith(id: 't1', name: 'Zeynep Ak'),
      participantWith(
        id: 't2',
        name: 'Ali Veli',
        status: TicketStatus.checkedIn,
        checkedInAt: DateTime.utc(2026, 11, 26, 4, 50),
        method: CheckInMethod.qr,
      ),
      participantWith(id: 't3', name: 'Ayşe Kaya', phone: null),
    ];

    DepartureCubit build() {
      when(() => repository.getCachedDepartures()).thenAnswer((_) async => [departure]);
      when(() => repository.getCachedParticipants('dep-1')).thenAnswer((_) async => null);
      when(() => repository.refreshParticipants('dep-1')).thenAnswer((_) async => participants);
      return DepartureCubit(repository, clock: () => DateTime.utc(2026, 11, 26, 6));
    }

    test('liste: gelmeyenler önce; süzgeç ve arama cihazda', () async {
      final cubit = build();
      await cubit.load('dep-1');

      expect(cubit.state.visibleParticipants.map((p) => p.ticketId), ['t3', 't1', 't2']);
      expect(cubit.state.arrivedCount, 1);
      expect(cubit.state.notArrivedCount, 2);
      expect(cubit.state.canRequestCompletion, isTrue);

      cubit.setFilter(ParticipantFilter.arrived);
      expect(cubit.state.visibleParticipants.single.ticketId, 't2');
      cubit
        ..setFilter(ParticipantFilter.notArrived)
        ..search('zeynep');
      expect(cubit.state.visibleParticipants.single.ticketId, 't1');
      verify(() => repository.refreshParticipants('dep-1')).called(1);
      await cubit.close();
    });

    test('katılımcı durum metni: saat ve elle işareti', () {
      expect(participants[0].statusLabel, 'Gelmedi');
      expect(participants[1].statusLabel, startsWith('Geldi · '));
      final manual = participants[0].checkedIn(DateTime.utc(2026, 11, 26, 5), CheckInMethod.manual);
      expect(manual.statusLabel, endsWith('· elle'));
    });

    test('elle "Geldi" yolcuyu yeşile çevirir', () async {
      when(() => repository.checkInManually('t1')).thenAnswer(
        (_) async => CheckInResult(
          code: CheckInCode.ok,
          ticketId: 't1',
          passengerName: 'Zeynep Ak',
          scannedAt: DateTime.utc(2026, 11, 26, 5, 5),
        ),
      );
      final cubit = build();
      await cubit.load('dep-1');
      await cubit.checkInManually(participants[0]);

      final zeynep = cubit.state.participants.firstWhere((p) => p.ticketId == 't1');
      expect(zeynep.hasArrived, isTrue);
      expect(zeynep.checkInMethod, CheckInMethod.manual);
      expect(cubit.state.lastCheckIn?.isSuccess, isTrue);
      expect(cubit.state.arrivedCount, 2);
      await cubit.close();
    });

    test('turu bitir hatası state\'e yazılır', () async {
      when(
        () => repository.requestCompletion('dep-1'),
      ).thenThrow(const GuideFailure(GuideFailureReason.departureNotStarted));
      final cubit = build();
      await cubit.load('dep-1');
      await cubit.requestCompletion();
      expect(cubit.state.actionStatus, DepartureAction.failure);
      expect(cubit.state.actionFailure, GuideFailureReason.departureNotStarted);
      await cubit.close();
    });

    test('bitirme talebinden sonra kalkış değişikliği ekrana yansır, okutma kapanır', () async {
      when(() => repository.requestCompletion('dep-1')).thenAnswer((_) async {
        changes.add([departure.copyWith(status: DepartureStatus.finishRequested)]);
      });
      final cubit = build();
      await cubit.load('dep-1');
      await cubit.requestCompletion();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.departure?.isAwaitingApproval, isTrue);
      expect(cubit.state.canCheckIn, isFalse);
      expect(cubit.state.canRequestCompletion, isFalse);
      await cubit.close();
    });

    test('kalkış cihazda ve sunucuda yoksa "bulunamadı"', () async {
      when(() => repository.getCachedDepartures()).thenAnswer((_) async => const []);
      when(() => repository.getCachedParticipants('x')).thenAnswer((_) async => null);
      when(() => repository.refreshDepartures()).thenAnswer((_) async => const []);
      final cubit = DepartureCubit(repository);
      await cubit.load('x');
      expect(cubit.state.status, DepartureViewStatus.notFound);
      await cubit.close();
    });
  });

  group('ScanCubit', () {
    var now = DateTime.utc(2026, 11, 26, 5);
    const ok = CheckInResult(code: CheckInCode.ok, ticketId: 't1', passengerName: 'Ali');

    ScanCubit build() {
      now = DateTime.utc(2026, 11, 26, 5);
      when(
        () => repository.scanTicket(
          departureId: 'dep-1',
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => ok);
      return ScanCubit(repository, clock: () => now)..start('dep-1');
    }

    test('okutma sonucu gösterilir; sonuç ekrandayken yeni kod yok sayılır', () async {
      final cubit = build();
      await cubit.submit('kod-1');
      expect(cubit.state.status, ScanStatus.result);
      expect(cubit.state.result, ok);
      expect(cubit.state.successCount, 1);

      await cubit.submit('kod-2');
      verify(() => repository.scanTicket(departureId: 'dep-1', code: 'kod-1')).called(1);
      verifyNever(() => repository.scanTicket(departureId: 'dep-1', code: 'kod-2'));
      await cubit.close();
    });

    test('aynı kod koruma süresi içinde tekrar okunmaz, süre geçince okunur', () async {
      final cubit = build();
      await cubit.submit('kod-1');
      cubit.next();
      expect(cubit.state.status, ScanStatus.scanning);
      expect(cubit.state.successCount, 1);

      now = now.add(AppDurations.scanRepeatGuard - const Duration(milliseconds: 1));
      await cubit.submit('kod-1');
      expect(cubit.state.status, ScanStatus.scanning);

      now = now.add(const Duration(seconds: 1));
      await cubit.submit('kod-1');
      expect(cubit.state.status, ScanStatus.result);
      verify(() => repository.scanTicket(departureId: 'dep-1', code: 'kod-1')).called(2);
      await cubit.close();
    });

    test('internet yoksa hata gösterilir, "Sıradaki yolcu" ile kameraya dönülür', () async {
      final cubit = build();
      when(
        () => repository.scanTicket(
          departureId: 'dep-1',
          code: any(named: 'code'),
        ),
      ).thenThrow(const GuideFailure(GuideFailureReason.network));
      await cubit.submit('kod-1');
      expect(cubit.state.status, ScanStatus.failure);
      expect(cubit.state.failure, GuideFailureReason.network);
      cubit.next();
      expect(cubit.state.isCameraActive, isTrue);
      await cubit.close();
    });

    test('boş kod gönderilmez', () async {
      final cubit = build();
      await cubit.submit('   ');
      verifyNever(
        () => repository.scanTicket(
          departureId: any(named: 'departureId'),
          code: any(named: 'code'),
        ),
      );
      await cubit.close();
    });
  });

  test('okutma sonucu ve hata metinleri her kod için dolu', () {
    for (final code in CheckInCode.values) {
      final result = CheckInResult(code: code);
      expect(result.title, isNotEmpty);
      expect(result.message, isNotEmpty);
    }
    for (final reason in GuideFailureReason.values) {
      expect(reason.message, isNotEmpty);
    }
  });
}
