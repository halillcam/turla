import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_mobile/features/tickets/domain/entities/ticket.dart';
import 'package:turla_mobile/features/tickets/domain/entities/ticket_failure.dart';
import 'package:turla_mobile/features/tickets/domain/repositories/ticket_repository.dart';
import 'package:turla_mobile/features/tickets/presentation/cubit/checkout_cubit.dart';
import 'package:turla_mobile/features/tickets/presentation/cubit/my_tickets_cubit.dart';
import 'package:turla_mobile/features/tickets/presentation/cubit/ticket_detail_cubit.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour_departure.dart';
import 'package:turla_mobile/features/tours/domain/repositories/tour_repository.dart';
import 'package:turla_mobile/features/tours/presentation/cubit/tour_detail_cubit.dart';

import '../../helpers/fixtures.dart';

class _MockTicketRepository extends Mock implements TicketRepository {}

class _MockTourRepository extends Mock implements TourRepository {}

void main() {
  late _MockTicketRepository repository;
  late StreamController<List<Ticket>> changes;
  final cached = [ticketWith(id: 'cached')];
  final fresh = [ticketWith(id: 'fresh')];

  setUpAll(() => registerFallbackValue(ticketWith()));

  setUp(() {
    repository = _MockTicketRepository();
    changes = StreamController.broadcast();
    when(() => repository.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  group('MyTicketsCubit', () {
    blocTest<MyTicketsCubit, MyTicketsState>(
      'önce cihazdaki liste, sonra sunucudaki liste',
      build: () {
        when(() => repository.getCachedTickets()).thenAnswer((_) async => cached);
        when(() => repository.refreshTickets()).thenAnswer((_) async => fresh);
        return MyTicketsCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        MyTicketsState(status: MyTicketsStatus.ready, tickets: cached),
        MyTicketsState(status: MyTicketsStatus.ready, tickets: cached, isRefreshing: true),
        MyTicketsState(status: MyTicketsStatus.ready, tickets: fresh),
      ],
    );

    blocTest<MyTicketsCubit, MyTicketsState>(
      'internet yoksa cihazdaki liste "eski veri" olarak kalır',
      build: () {
        when(() => repository.getCachedTickets()).thenAnswer((_) async => cached);
        when(
          () => repository.refreshTickets(),
        ).thenThrow(const TicketFailure(TicketFailureReason.network));
        return MyTicketsCubit(repository);
      },
      act: (cubit) => cubit.load(),
      skip: 2,
      expect: () => [
        MyTicketsState(
          status: MyTicketsStatus.ready,
          tickets: cached,
          isStale: true,
          failure: TicketFailureReason.network,
        ),
      ],
    );

    blocTest<MyTicketsCubit, MyTicketsState>(
      'cihazda bilet yok ve internet yoksa hata gösterilir',
      build: () {
        when(() => repository.getCachedTickets()).thenAnswer((_) async => []);
        when(
          () => repository.refreshTickets(),
        ).thenThrow(const TicketFailure(TicketFailureReason.network));
        return MyTicketsCubit(repository);
      },
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        const MyTicketsState(status: MyTicketsStatus.failure, failure: TicketFailureReason.network),
      ],
    );

    blocTest<MyTicketsCubit, MyTicketsState>(
      'başka ekranda alınan/iptal edilen bilet listeye istek atmadan yansır',
      build: () => MyTicketsCubit(repository),
      act: (cubit) => changes.add(fresh),
      expect: () => [MyTicketsState(status: MyTicketsStatus.ready, tickets: fresh)],
    );
  });

  group('CheckoutCubit', () {
    final ticket = ticketWith(id: 'new');

    blocTest<CheckoutCubit, CheckoutState>(
      'başarılı satın alma bileti döndürür',
      build: () {
        when(
          () => repository.bookTicket(departureId: 'dep', passengerName: 'Ali Veli'),
        ).thenAnswer((_) async => ticket);
        return CheckoutCubit(repository);
      },
      act: (cubit) => cubit.purchase(departureId: 'dep', passengerName: 'Ali Veli'),
      expect: () => [
        const CheckoutState(status: CheckoutStatus.submitting),
        CheckoutState(status: CheckoutStatus.success, ticket: ticket),
      ],
    );

    blocTest<CheckoutCubit, CheckoutState>(
      'koltuk kalmadıysa hata türü state\'e yazılır',
      build: () {
        when(
          () => repository.bookTicket(
            departureId: any(named: 'departureId'),
            passengerName: any(named: 'passengerName'),
          ),
        ).thenThrow(const TicketFailure(TicketFailureReason.noSeatsLeft));
        return CheckoutCubit(repository);
      },
      act: (cubit) => cubit.purchase(departureId: 'dep', passengerName: 'Ali Veli'),
      expect: () => [
        const CheckoutState(status: CheckoutStatus.submitting),
        const CheckoutState(
          status: CheckoutStatus.failure,
          failure: TicketFailureReason.noSeatsLeft,
        ),
      ],
    );
  });

  group('TicketDetailCubit', () {
    final departure = DateTime.utc(2026, 12, 5, 7);
    final ticket = ticketWith(id: 'a', departureAt: departure);
    DateTime early() => departure.subtract(const Duration(days: 1));

    blocTest<TicketDetailCubit, TicketDetailState>(
      'bilet cihazdan açılır (istek yok), iptal edilebilir',
      build: () {
        when(() => repository.getCachedTickets()).thenAnswer((_) async => [ticket]);
        return TicketDetailCubit(repository, clock: early);
      },
      act: (cubit) => cubit.load('a'),
      expect: () => [
        TicketDetailState(status: TicketDetailStatus.ready, ticket: ticket, canCancel: true),
      ],
      verify: (_) => verifyNever(() => repository.refreshTickets()),
    );

    blocTest<TicketDetailCubit, TicketDetailState>(
      'kalkışa 1 saatten az kala iptal düğmesi çıkmaz',
      build: () {
        when(() => repository.getCachedTickets()).thenAnswer((_) async => [ticket]);
        return TicketDetailCubit(
          repository,
          clock: () => departure.subtract(const Duration(minutes: 30)),
        );
      },
      act: (cubit) => cubit.load('a'),
      expect: () => [TicketDetailState(status: TicketDetailStatus.ready, ticket: ticket)],
    );

    blocTest<TicketDetailCubit, TicketDetailState>(
      'cihazda olmayan bilet bulunamadı olarak gösterilir',
      build: () {
        when(() => repository.getCachedTickets()).thenAnswer((_) async => []);
        return TicketDetailCubit(repository, clock: early);
      },
      act: (cubit) => cubit.load('yok'),
      expect: () => [const TicketDetailState(status: TicketDetailStatus.notFound)],
    );

    final cancelled = ticket.cancelled(DateTime.utc(2026, 12, 1));

    blocTest<TicketDetailCubit, TicketDetailState>(
      'iptal başarılı → bilet iptal edildi, iptal düğmesi kalkar',
      build: () {
        when(() => repository.getCachedTickets()).thenAnswer((_) async => [ticket]);
        when(() => repository.cancelTicket(ticket)).thenAnswer((_) async => cancelled);
        return TicketDetailCubit(repository, clock: early);
      },
      act: (cubit) async {
        await cubit.load('a');
        await cubit.cancel();
      },
      skip: 1,
      expect: () => [
        TicketDetailState(
          status: TicketDetailStatus.ready,
          ticket: ticket,
          canCancel: true,
          cancelStatus: CancelStatus.inProgress,
        ),
        TicketDetailState(
          status: TicketDetailStatus.ready,
          ticket: cancelled,
          cancelStatus: CancelStatus.success,
        ),
      ],
    );

    blocTest<TicketDetailCubit, TicketDetailState>(
      'sunucu iptali reddederse hata türü gösterilir, bilet değişmez',
      build: () {
        when(() => repository.getCachedTickets()).thenAnswer((_) async => [ticket]);
        when(
          () => repository.cancelTicket(any()),
        ).thenThrow(const TicketFailure(TicketFailureReason.cancellationWindowClosed));
        return TicketDetailCubit(repository, clock: early);
      },
      act: (cubit) async {
        await cubit.load('a');
        await cubit.cancel();
      },
      skip: 2,
      expect: () => [
        TicketDetailState(
          status: TicketDetailStatus.ready,
          ticket: ticket,
          canCancel: true,
          cancelStatus: CancelStatus.failure,
          failure: TicketFailureReason.cancellationWindowClosed,
        ),
      ],
    );
  });

  group('TourDetailCubit kalkış seçimi', () {
    final base = tourWith();
    final tour = Tour(
      id: base.id,
      title: base.title,
      description: base.description,
      extraDetail: base.extraDetail,
      price: base.price,
      region: base.region,
      cityId: base.cityId,
      companyName: base.companyName,
      departures: [
        TourDeparture(
          id: 'full',
          departureAt: DateTime.utc(2030, 1, 1),
          seatsLeft: 0,
          capacity: 10,
        ),
        TourDeparture(
          id: 'open',
          departureAt: DateTime.utc(2030, 1, 8),
          seatsLeft: 3,
          capacity: 10,
        ),
      ],
    );
    late _MockTourRepository tours;

    setUp(() {
      tours = _MockTourRepository();
      when(() => tours.getTourDetail(any())).thenAnswer((_) async => tour);
    });

    blocTest<TourDetailCubit, TourDetailState>(
      'varsayılan seçim boş koltuğu olan ilk tarih; dolu tarih seçilemez',
      build: () => TourDetailCubit(tours),
      act: (cubit) async {
        await cubit.load(tour.id);
        cubit.selectDeparture('full');
      },
      expect: () => [
        const TourDetailState(status: TourDetailStatus.loading),
        TourDetailState(status: TourDetailStatus.ready, tour: tour, selectedDepartureId: 'open'),
      ],
      verify: (cubit) => expect(cubit.state.canBuy, isTrue),
    );
  });
}
