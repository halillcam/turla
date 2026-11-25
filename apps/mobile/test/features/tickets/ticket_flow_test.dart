import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/app/router/app_routes.dart';
import 'package:turla_mobile/core/constants/strings.dart';
import 'package:turla_mobile/core/di/injection.dart';
import 'package:turla_mobile/features/auth/presentation/bloc/session_bloc.dart';
import 'package:turla_mobile/features/tickets/domain/entities/ticket.dart';
import 'package:turla_mobile/features/tickets/domain/entities/ticket_failure.dart';
import 'package:turla_mobile/features/tickets/domain/repositories/ticket_repository.dart';
import 'package:turla_mobile/features/tickets/presentation/cubit/checkout_cubit.dart';
import 'package:turla_mobile/features/tickets/presentation/cubit/ticket_detail_cubit.dart';
import 'package:turla_mobile/features/tickets/presentation/screens/checkout_screen.dart';
import 'package:turla_mobile/features/tickets/presentation/screens/ticket_detail_screen.dart';

import '../../helpers/fixtures.dart';

class _MockTicketRepository extends Mock implements TicketRepository {}

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc {}

const _myTicketsText = 'Turlarım sayfası';

final _args = CheckoutArgs(
  tourTitle: 'Kapadokya Turu',
  companyName: 'Demo Turizm',
  price: 1850,
  departureId: 'dep-1',
  departureAt: DateTime.utc(2026, 12, 5, 7),
);

Widget _app(Widget home, SessionBloc session) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(path: AppRoutes.myTickets, builder: (_, _) => const Text(_myTicketsText)),
      GoRoute(path: AppRoutes.tours, builder: (_, _) => const Text('Turlar')),
    ],
  );
  return BlocProvider<SessionBloc>.value(
    value: session,
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Liste uzun olduğu için düğme ekran dışında kalabilir; önce görünür yapılır.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  late _MockTicketRepository repository;
  late _MockSessionBloc session;

  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    registerFallbackValue(ticketWith());
  });

  setUp(() {
    repository = _MockTicketRepository();
    session = _MockSessionBloc();
    when(() => session.state).thenReturn(SessionState.signedIn(profileWith(UserRole.customer)));
    when(() => repository.changes).thenAnswer((_) => const Stream.empty());
    getIt
      ..registerFactory<CheckoutCubit>(() => CheckoutCubit(repository))
      ..registerFactory<TicketDetailCubit>(
        () => TicketDetailCubit(repository, clock: () => DateTime.utc(2026, 12, 1)),
      );
  });

  tearDown(() => getIt.reset());

  testWidgets('demo ödeme: ad ve telefon profilden gelir, ödeme sonrası QR ve Turlarım geçişi', (
    tester,
  ) async {
    final ticket = ticketWith(id: 'new');
    when(
      () => repository.bookTicket(
        departureId: 'dep-1',
        passengerName: 'Test Kullanıcı',
        passengerPhone: '0532 111 22 33',
      ),
    ).thenAnswer((_) async => ticket);

    await tester.pumpWidget(_app(CheckoutScreen(args: _args), session));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.demoPaymentNote), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Test Kullanıcı'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '0532 111 22 33'), findsOneWidget);

    await _tapVisible(tester, find.textContaining(AppStrings.completePayment));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.purchaseSuccessTitle), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);

    await _tapVisible(tester, find.text(AppStrings.goToMyTickets));
    await tester.pumpAndSettle();
    expect(find.text(_myTicketsText), findsOneWidget);
  });

  testWidgets('ad/telefon boşsa ödeme yapılmaz; sunucu hatası Türkçe gösterilir', (tester) async {
    when(() => session.state).thenReturn(
      const SessionState.signedIn(
        UserProfile(id: 'u', email: 'a@b.c', fullName: '', role: UserRole.customer, isActive: true),
      ),
    );
    when(
      () => repository.bookTicket(
        departureId: any(named: 'departureId'),
        passengerName: any(named: 'passengerName'),
        passengerPhone: any(named: 'passengerPhone'),
      ),
    ).thenThrow(const TicketFailure(TicketFailureReason.noSeatsLeft));

    await tester.pumpWidget(_app(CheckoutScreen(args: _args), session));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.textContaining(AppStrings.completePayment));
    await tester.pumpAndSettle();
    // Ad ve telefon ikisi de boş.
    expect(find.text(AppStrings.fieldRequired), findsNWidgets(2));
    verifyNever(
      () => repository.bookTicket(
        departureId: any(named: 'departureId'),
        passengerName: any(named: 'passengerName'),
        passengerPhone: any(named: 'passengerPhone'),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Ali Veli');
    await tester.enterText(find.byKey(const Key('checkout-phone')), 'telefon');
    await _tapVisible(tester, find.textContaining(AppStrings.completePayment));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.invalidPhone), findsOneWidget);

    await tester.enterText(find.byKey(const Key('checkout-phone')), '0532 111 22 33');
    await _tapVisible(tester, find.textContaining(AppStrings.completePayment));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.errorNoSeatsLeft), findsOneWidget);
  });

  testWidgets('bilet detayı: QR cihazdan açılır, onaylanınca iptal edilir ve iade görünür', (
    tester,
  ) async {
    final ticket = ticketWith(id: 'a');
    final cancelled = ticket.cancelled(DateTime.utc(2026, 12, 1, 9));
    when(() => repository.getCachedTickets()).thenAnswer((_) async => [ticket]);
    when(() => repository.cancelTicket(ticket)).thenAnswer((_) async => cancelled);

    await tester.pumpWidget(_app(const TicketDetailScreen(ticketId: 'a'), session));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    verifyNever(() => repository.refreshTickets());

    await _tapVisible(tester, find.text(AppStrings.cancelTicket));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.cancelDialogTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.cancelDialogConfirm));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.ticketCancelledMessage), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text(AppStrings.refundedPrefix), findsOneWidget);
    expect(find.text(AppStrings.cancelTicket), findsNothing);
  });

  testWidgets('iptal penceresinde vazgeçilirse sunucuya gidilmez', (tester) async {
    final completer = Completer<Ticket>();
    when(() => repository.getCachedTickets()).thenAnswer((_) async => [ticketWith(id: 'a')]);
    when(() => repository.cancelTicket(any())).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_app(const TicketDetailScreen(ticketId: 'a'), session));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.cancelTicket));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.cancelDialogDismiss));
    await tester.pumpAndSettle();

    verifyNever(() => repository.cancelTicket(any()));
  });
}
