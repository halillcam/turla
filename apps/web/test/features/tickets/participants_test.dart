import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_web/core/bloc/load_status.dart';
import 'package:turla_web/core/constants/strings.dart';
import 'package:turla_web/core/di/injection.dart';
import 'package:turla_web/core/errors/panel_failure.dart';
import 'package:turla_web/core/errors/panel_guard.dart';
import 'package:turla_web/core/utils/failure_messages.dart';
import 'package:turla_web/features/staff/domain/entities/staff_member.dart';
import 'package:turla_web/features/staff/domain/repositories/account_repository.dart';
import 'package:turla_web/features/tickets/data/models/participant_ticket_model.dart';
import 'package:turla_web/features/tickets/domain/entities/participant_ticket.dart';
import 'package:turla_web/features/tickets/domain/repositories/ticket_admin_repository.dart';
import 'package:turla_web/features/tickets/presentation/cubit/participants_cubit.dart';
import 'package:turla_web/features/tickets/presentation/utils/participant_display.dart';
import 'package:turla_web/features/tickets/presentation/widgets/participants_dialog.dart';
import 'package:turla_web/features/tours/domain/entities/departure.dart';

import '../../helpers/fixtures.dart';

class _MockTickets extends Mock implements TicketAdminRepository {}

class _MockAccounts extends Mock implements AccountRepository {}

ParticipantTicket _ticket(
  String id, {
  TicketStatus status = TicketStatus.paid,
  bool isFromPanel = false,
  String name = 'Yolcu',
}) => ParticipantTicket(
  id: id,
  departureId: 'd1',
  userId: 'u-$id',
  passengerName: '$name $id',
  status: status,
  isFromPanel: isFromPanel,
  pricePaid: 500,
  createdAt: DateTime.utc(2026, 11, 20, 10),
);

const _customer = StaffMember(
  id: 'c1',
  fullName: 'Ayşe Kaya',
  role: UserRole.customer,
  isActive: true,
  loginId: 'MUS-1234',
);

void main() {
  final dep = departure('d1', DateTime.utc(2026, 12, 5, 7));
  late _MockTickets tickets;
  late _MockAccounts accounts;

  setUpAll(() => initializeDateFormatting('tr_TR'));

  setUp(() {
    tickets = _MockTickets();
    accounts = _MockAccounts();
    when(() => tickets.listDepartureTickets('d1')).thenAnswer(
      (_) async => [_ticket('a'), _ticket('b', status: TicketStatus.cancelled), _ticket('c')],
    );
    when(
      () => accounts.listMembers(companyA, roles: const [UserRole.customer], activeOnly: true),
    ).thenAnswer((_) async => [_customer]);
  });

  ParticipantsCubit build() => ParticipantsCubit(
    companyId: companyA,
    departure: dep,
    ticketRepository: tickets,
    accountRepository: accounts,
  );

  group('ParticipantsCubit', () {
    test('biletler ve bilet kesilebilecek aktif müşteriler birlikte yüklenir', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.soldSeats, 2);
      expect(cubit.state.sortedTickets.map((t) => t.id), ['a', 'c', 'b']);
      expect(cubit.state.customers.single.loginId, 'MUS-1234');
    });

    test('iptal yerelde güncellenir, satılan koltuk düşer (liste yeniden çekilmez)', () async {
      when(
        () => tickets.cancelTicket('a'),
      ).thenAnswer((_) async => _ticket('a', status: TicketStatus.cancelled));
      final cubit = build();
      await cubit.load();

      final result = await cubit.cancel('a');

      expect(result.isSuccess, isTrue);
      expect(cubit.state.soldSeats, 1);
      verify(() => tickets.listDepartureTickets('d1')).called(1);
    });

    test('panelden bilet kesilince listeye eklenir', () async {
      when(
        () => tickets.issueTicket(departureId: 'd1', customerId: 'c1', passengerName: ''),
      ).thenAnswer((_) async => _ticket('new', isFromPanel: true));
      final cubit = build();
      await cubit.load();

      final result = await cubit.issue(customerId: 'c1', passengerName: '');

      expect(result.value?.isFromPanel, isTrue);
      expect(cubit.state.soldSeats, 3);
    });

    test('sunucu reddederse hata döner, liste değişmez', () async {
      when(
        () => tickets.issueTicket(
          departureId: any(named: 'departureId'),
          customerId: any(named: 'customerId'),
          passengerName: any(named: 'passengerName'),
        ),
      ).thenThrow(const PanelFailure(PanelFailureReason.noSeatsLeft));
      final cubit = build();
      await cubit.load();

      final result = await cubit.issue(customerId: 'c1');

      expect(result.failure, PanelFailureReason.noSeatsLeft);
      expect(cubit.state.tickets, hasLength(3));
      expect(cubit.state.isBusy, isFalse);
    });
  });

  test('bilet satırı okunur: kaynak panel/uygulama', () {
    final row = {
      'id': 't1',
      'departure_id': 'd1',
      'user_id': 'u1',
      'passenger_name': 'Ali',
      'status': 'paid',
      'source': 'panel',
      'price_paid': 750.5,
      'created_at': '2026-11-20T10:00:00Z',
      'cancelled_at': null,
      'qr_token': 'panelde kullanılmaz',
    };
    final ticket = ParticipantTicketModel.fromRow(row);
    expect(ticket.isFromPanel, isTrue);
    expect(ticket.pricePaid, 750.5);
    expect(ticket.isCancellable, isTrue);
    expect(ParticipantTicketModel.fromRow({...row, 'source': 'app'}).isFromPanel, isFalse);
    expect(ticket.phoneLabel, AppStrings.empty);
    expect(ticket.statusLabel, TicketStatus.paid.label);
  });

  test('yolcu telefonu ve rehberin elle işaretlemesi tabloda görünür', () {
    final ticket = ParticipantTicketModel.fromRow({
      'id': 't1',
      'departure_id': 'd1',
      'user_id': 'u1',
      'passenger_name': 'Ali',
      'status': 'checked_in',
      'source': 'app',
      'price_paid': 750,
      'created_at': '2026-11-20T10:00:00Z',
      'cancelled_at': null,
      'passenger_phone': '0532 111 22 33',
      'scanned_at': '2026-11-26T05:10:00Z',
      'check_in_method': 'manual',
    });
    expect(ticket.phoneLabel, '0532 111 22 33');
    expect(ticket.isManualCheckIn, isTrue);
    expect(ticket.checkedInAt, DateTime.utc(2026, 11, 26, 5, 10));
    expect(ticket.statusLabel, '${TicketStatus.checkedIn.label} ${AppStrings.manualCheckInSuffix}');
  });

  test('bilet hata kodları eşlenir ve her birinin mesajı var', () {
    const codes = {
      'invalid_customer': PanelFailureReason.invalidCustomer,
      'already_has_ticket': PanelFailureReason.alreadyHasTicket,
      'no_seats_left': PanelFailureReason.noSeatsLeft,
      'departure_not_bookable': PanelFailureReason.departureNotBookable,
      'ticket_not_cancellable': PanelFailureReason.ticketNotCancellable,
      'ticket_not_found': PanelFailureReason.notFound,
    };
    codes.forEach((code, reason) {
      expect(PanelErrorMapper.fromPostgrest('P0001', code), reason);
      expect(reason.message, isNotEmpty);
    });
    final messages = PanelFailureReason.values.map((reason) => reason.message).toList();
    expect(messages.toSet().length, messages.length);
  });

  group('Katılımcı penceresi', () {
    setUp(() {
      getIt.registerFactoryParam<ParticipantsCubit, String, Departure>(
        (companyId, departure) => ParticipantsCubit(
          companyId: companyId,
          departure: departure,
          ticketRepository: tickets,
          accountRepository: accounts,
        ),
      );
    });

    tearDown(() => getIt.reset());

    /// Pencereyi açar; kapanınca dönen satılan koltuk sayısı [onClosed]'a verilir.
    Future<void> open(WidgetTester tester, {ValueChanged<int?>? onClosed}) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final sold = await showParticipantsDialog(
                    context,
                    companyId: companyA,
                    departure: dep,
                  );
                  onClosed?.call(sold);
                },
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
    }

    testWidgets('yönetici iptali: onay → bilet iptal, kapanınca güncel satılan koltuk döner', (
      tester,
    ) async {
      when(
        () => tickets.cancelTicket('a'),
      ).thenAnswer((_) async => _ticket('a', status: TicketStatus.cancelled));
      int? sold;
      await open(tester, onClosed: (value) => sold = value);

      expect(find.text('Yolcu a'), findsOneWidget);
      expect(find.textContaining('2 / 10'), findsOneWidget);

      await tester.tap(find.byTooltip(AppStrings.cancelTicket).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.cancelTicket));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 / 10'), findsOneWidget);
      await tester.tap(find.text(AppStrings.close));
      await tester.pumpAndSettle();
      expect(sold, 1);
    });

    testWidgets('bilet kes: müşteri seçilmeden kesilmez, seçilince listeye eklenir', (
      tester,
    ) async {
      when(
        () => tickets.issueTicket(departureId: 'd1', customerId: 'c1', passengerName: ''),
      ).thenAnswer((_) async => _ticket('new', isFromPanel: true, name: 'Ayşe'));
      await open(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.issueTicketTitle), findsOneWidget);

      // Müşteri seçmeden gönder → doğrulama hatası.
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.issueTicket).last);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.fieldRequired), findsOneWidget);

      await tester.tap(find.text(AppStrings.issueTicketCustomer));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ayşe Kaya (MUS-1234)').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.issueTicket).last);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.issueTicketTitle), findsNothing);
      expect(find.text('Ayşe new'), findsOneWidget);
      expect(find.text(AppStrings.ticketSourcePanel), findsOneWidget);
    });
  });
}
