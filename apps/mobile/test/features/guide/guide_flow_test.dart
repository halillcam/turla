import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/core/constants/strings.dart';
import 'package:turla_mobile/core/di/injection.dart';
import 'package:turla_mobile/features/guide/domain/entities/check_in_result.dart';
import 'package:turla_mobile/features/guide/domain/repositories/guide_repository.dart';
import 'package:turla_mobile/features/guide/presentation/cubit/departure_cubit.dart';
import 'package:turla_mobile/features/guide/presentation/cubit/scan_cubit.dart';
import 'package:turla_mobile/features/guide/presentation/screens/departure_screen.dart';
import 'package:turla_mobile/features/guide/presentation/screens/scan_screen.dart';
import 'package:turla_mobile/features/guide/presentation/widgets/camera_error_view.dart';
import 'package:turla_mobile/features/tickets/presentation/widgets/ticket_detail_view.dart';
import 'package:turla_mobile/features/tickets/presentation/widgets/ticket_qr_card.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/guide_fixtures.dart';

class _MockGuideRepository extends Mock implements GuideRepository {}

/// Kamera yerine "okuttum" düğmesi: testte gerçek kamera açılmaz.
Widget _fakeScanner(ValueChanged<String> onCode, VoidCallback onEnterCode) => Column(
  children: [
    TextButton(onPressed: () => onCode('qr-ok'), child: const Text('sahte-okut')),
    TextButton(onPressed: onEnterCode, child: const Text(AppStrings.enterCodeManually)),
  ],
);

Widget _app(Widget home) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Text('liste'),
        routes: [GoRoute(path: 'screen', builder: (_, _) => home)],
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  late _MockGuideRepository repository;

  setUpAll(() => initializeDateFormatting('tr_TR'));

  setUp(() {
    repository = _MockGuideRepository();
    when(() => repository.departureChanges).thenAnswer((_) => const Stream.empty());
    getIt
      ..registerFactory<ScanCubit>(() => ScanCubit(repository))
      ..registerFactory<DepartureCubit>(
        () => DepartureCubit(repository, clock: () => DateTime.utc(2026, 11, 26, 4)),
      );
  });

  tearDown(() => getIt.reset());

  testWidgets('QR okutma: sonuç ekranı yolcu adını gösterir, "Sıradaki yolcu" kameraya döner', (
    tester,
  ) async {
    when(() => repository.scanTicket(departureId: 'dep-1', code: 'qr-ok')).thenAnswer(
      (_) async =>
          const CheckInResult(code: CheckInCode.ok, ticketId: 't1', passengerName: 'Ali Veli'),
    );

    await tester.pumpWidget(
      _app(const ScanScreen(departureId: 'dep-1', scannerBuilder: _fakeScanner)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('sahte-okut'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.scanOkTitle), findsOneWidget);
    expect(find.text('Ali Veli'), findsOneWidget);
    expect(find.text('sahte-okut'), findsNothing);

    await tester.tap(find.text(AppStrings.nextPassenger));
    await tester.pumpAndSettle();
    expect(find.text('sahte-okut'), findsOneWidget);
  });

  testWidgets('kodu elle gir: başka tarihin bileti uyarısı', (tester) async {
    when(
      () => repository.scanTicket(departureId: 'dep-1', code: 'elle-kod'),
    ).thenAnswer((_) async => const CheckInResult(code: CheckInCode.wrongDeparture));

    await tester.pumpWidget(
      _app(const ScanScreen(departureId: 'dep-1', scannerBuilder: _fakeScanner)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.enterCodeManually));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('manual-code-field')), ' elle-kod ');
    await tester.tap(find.text(AppStrings.enterCodeSubmit));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.scanWrongDepartureTitle), findsOneWidget);
    verify(() => repository.scanTicket(departureId: 'dep-1', code: 'elle-kod')).called(1);
  });

  testWidgets('kamera izni reddedilince açıklama ve "Kodu elle gir" görünür', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraErrorView(permissionDenied: true, onEnterCode: () => tapped = true),
        ),
      ),
    );
    expect(find.text(AppStrings.cameraPermissionDenied), findsOneWidget);
    await tester.tap(find.text(AppStrings.enterCodeManually));
    expect(tapped, isTrue);
  });

  testWidgets('katılımcılar: kırmızı Gelmedi → onayla → yeşil Geldi (elle)', (tester) async {
    final departure = departureWith(departureAt: DateTime.utc(2026, 11, 26, 5));
    when(() => repository.getCachedDepartures()).thenAnswer((_) async => [departure]);
    when(() => repository.getCachedParticipants('dep-1')).thenAnswer((_) async => null);
    when(
      () => repository.refreshParticipants('dep-1'),
    ).thenAnswer((_) async => [participantWith(id: 't1', name: 'Zeynep Ak')]);
    when(() => repository.checkInManually('t1')).thenAnswer(
      (_) async => CheckInResult(
        code: CheckInCode.ok,
        ticketId: 't1',
        passengerName: 'Zeynep Ak',
        scannedAt: DateTime.utc(2026, 11, 26, 4, 45),
      ),
    );

    await tester.pumpWidget(_app(const DepartureScreen(departureId: 'dep-1')));
    await tester.pumpAndSettle();

    expect(find.text('Zeynep Ak'), findsOneWidget);
    expect(find.widgetWithText(ListTile, AppStrings.notArrived), findsOneWidget);
    expect(find.text(AppStrings.scanQr), findsOneWidget);
    // Kalkış saati gelmedi (saat 04:00, kalkış 05:00): turu bitir gösterilmez.
    expect(find.text(AppStrings.finishTour), findsNothing);

    await tester.tap(find.text('Zeynep Ak'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.manualCheckInTitle), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(AppStrings.manualCheckInConfirm),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('${AppStrings.arrivedAtPrefix} · '), findsOneWidget);
    expect(find.textContaining(AppStrings.manualSuffix), findsOneWidget);
    expect(find.textContaining(AppStrings.manualCheckInDone), findsOneWidget);
  });

  testWidgets('bitirme talebi bekleyen tarihte okutma düğmesi yok, bant görünür', (tester) async {
    final departure = departureWith(status: DepartureStatus.finishRequested);
    when(() => repository.getCachedDepartures()).thenAnswer((_) async => [departure]);
    when(() => repository.getCachedParticipants('dep-1')).thenAnswer((_) async => null);
    when(
      () => repository.refreshParticipants('dep-1'),
    ).thenAnswer((_) async => [participantWith(id: 't1', name: 'Zeynep Ak')]);

    await tester.pumpWidget(_app(const DepartureScreen(departureId: 'dep-1')));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.awaitingApprovalBanner), findsOneWidget);
    expect(find.text(AppStrings.scanQr), findsNothing);
    await tester.tap(find.text('Zeynep Ak'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.manualCheckInTitle), findsNothing);
  });

  testWidgets('müşteri: okutulan bilette QR yerine "QR kodun okutuldu" görünür', (tester) async {
    final scanned = ticketWith(status: TicketStatus.checkedIn);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TicketDetailView(
            ticket: scanned,
            canCancel: false,
            isCancelling: false,
            onCancel: () {},
            onOpenActiveTour: () {},
          ),
        ),
      ),
    );
    expect(find.byType(TicketQrCard), findsNothing);
    expect(find.textContaining(AppStrings.qrScannedTitle), findsOneWidget);
    expect(find.text(TicketStatus.checkedIn.label), findsOneWidget);
  });
}
