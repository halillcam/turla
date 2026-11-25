import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_web/core/bloc/load_status.dart';
import 'package:turla_web/core/errors/panel_failure.dart';
import 'package:turla_web/features/completions/domain/entities/completion_request.dart';
import 'package:turla_web/features/completions/domain/repositories/completion_repository.dart';
import 'package:turla_web/features/completions/presentation/cubit/completions_cubit.dart';
import 'package:turla_web/features/staff/domain/entities/new_account.dart';
import 'package:turla_web/features/staff/domain/repositories/account_repository.dart';
import 'package:turla_web/features/staff/presentation/cubit/staff_cubit.dart';
import 'package:turla_web/features/tours/domain/entities/departure.dart';
import 'package:turla_web/features/tours/domain/repositories/tour_admin_repository.dart';
import 'package:turla_web/features/tours/presentation/cubit/departures_cubit.dart';

import '../helpers/fixtures.dart';

class _MockAccounts extends Mock implements AccountRepository {}

class _MockTours extends Mock implements TourAdminRepository {}

class _MockCompletions extends Mock implements CompletionRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const NewAccount(role: UserRole.guide, companyId: companyA, fullName: 'x', password: 'x'),
    );
    registerFallbackValue(DepartureDraft(departureAt: DateTime(2026), capacity: 1));
  });

  group('StaffCubit', () {
    late _MockAccounts accounts;

    setUp(() {
      accounts = _MockAccounts();
      when(
        () => accounts.listMembers(companyA, roles: StaffCubit.managedRoles),
      ).thenAnswer((_) async => [guide('g1')]);
    });

    test('rehber açınca giriş kimliğiyle listeye eklenir (liste yeniden çekilmez)', () async {
      when(() => accounts.createAccount(any())).thenAnswer(
        (_) async => const CreatedAccount(
          userId: 'g2',
          email: 'reh-1234@staff.turla.app',
          loginId: 'REH-1234',
        ),
      );
      final cubit = StaffCubit(companyId: companyA, accountRepository: accounts);
      await cubit.load();

      final result = await cubit.create(
        role: UserRole.guide,
        fullName: ' Yeni Rehber ',
        password: 'gizli1234',
      );

      expect(result.value?.loginId, 'REH-1234');
      expect(cubit.state.guides.map((g) => g.id), ['g1', 'g2']);
      expect(cubit.state.guides.last.fullName, 'Yeni Rehber');
      final sent = verify(() => accounts.createAccount(captureAny())).captured.single as NewAccount;
      expect(sent.companyId, companyA);
      expect(sent.role, UserRole.guide);
      verify(() => accounts.listMembers(companyA, roles: StaffCubit.managedRoles)).called(1);
      await cubit.close();
    });

    test('şifre sıfırlama yeni şifreyi döndürür, liste değişmez ve yeniden çekilmez', () async {
      when(() => accounts.resetPassword('g1')).thenAnswer((_) async => 'Yeni2345ab');
      final cubit = StaffCubit(companyId: companyA, accountRepository: accounts);
      await cubit.load();
      final before = cubit.state.members;

      final result = await cubit.resetPassword(cubit.state.guides.single);

      expect(result.value, 'Yeni2345ab');
      expect(cubit.state.members, before);
      expect(cubit.state.isBusy, isFalse);
      verify(() => accounts.listMembers(companyA, roles: StaffCubit.managedRoles)).called(1);
      await cubit.close();
    });

    test('sıfırlanamayan hesap hatası döner', () async {
      when(
        () => accounts.resetPassword('g1'),
      ).thenThrow(const PanelFailure(PanelFailureReason.notResettable));
      final cubit = StaffCubit(companyId: companyA, accountRepository: accounts);
      await cubit.load();
      final result = await cubit.resetPassword(cubit.state.guides.single);
      expect(result.failure, PanelFailureReason.notResettable);
      await cubit.close();
    });

    test('aktif/pasif hatası durumu değiştirmez', () async {
      when(
        () => accounts.setActive('g1', isActive: false),
      ).thenThrow(const PanelFailure(PanelFailureReason.notAllowed));
      final cubit = StaffCubit(companyId: companyA, accountRepository: accounts);
      await cubit.load();

      final result = await cubit.toggleActive(cubit.state.guides.single);

      expect(result.failure, PanelFailureReason.notAllowed);
      expect(cubit.state.guides.single.isActive, isTrue);
      expect(cubit.state.isBusy, isFalse);
      await cubit.close();
    });
  });

  group('DeparturesCubit', () {
    late _MockTours tours;
    late _MockAccounts accounts;
    final now = DateTime.utc(2026, 12, 1);

    setUp(() {
      tours = _MockTours();
      accounts = _MockAccounts();
      when(() => tours.listDepartures('tour-1')).thenAnswer(
        (_) async => [departure('d2', now.add(const Duration(days: 2)), guideId: 'old')],
      );
      when(
        () => accounts.listMembers(companyA, roles: const [UserRole.guide]),
      ).thenAnswer((_) async => [guide('g1'), guide('old', isActive: false)]);
    });

    test('pasif rehber atamada seçilemez ama adı görünür', () async {
      final cubit = DeparturesCubit(
        companyId: companyA,
        tourId: 'tour-1',
        tourRepository: tours,
        accountRepository: accounts,
      );
      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.assignableGuides.map((g) => g.id), ['g1']);
      expect(cubit.state.guideName('old'), 'Rehber old');
      await cubit.close();
    });

    test('yeni tarih tarih sırasına göre eklenir; kontenjan hatası döner', () async {
      when(
        () => tours.createDeparture('tour-1', any()),
      ).thenAnswer((_) async => departure('d1', now.add(const Duration(days: 1))));
      when(
        () => tours.updateDeparture('d2', any()),
      ).thenThrow(const PanelFailure(PanelFailureReason.capacityBelowSoldSeats));
      final cubit = DeparturesCubit(
        companyId: companyA,
        tourId: 'tour-1',
        tourRepository: tours,
        accountRepository: accounts,
      );
      await cubit.load();

      await cubit.create(
        DepartureDraft(departureAt: now.add(const Duration(days: 1)), capacity: 10),
      );
      expect(cubit.state.departures.map((d) => d.id), ['d1', 'd2']);

      final result = await cubit.update('d2', DepartureDraft(departureAt: now, capacity: 1));
      expect(result.failure, PanelFailureReason.capacityBelowSoldSeats);
      await cubit.close();
    });
  });

  group('CompletionsCubit', () {
    final pending = CompletionRequest(
      id: 'r1',
      departureId: 'd1',
      tourTitle: 'Göksun',
      departureAt: DateTime.utc(2026, 11, 23),
      guideName: 'Rıza',
      status: CompletionStatus.pending,
      createdAt: DateTime.utc(2026, 11, 24),
    );

    test('onaylanan talep listede güncellenir', () async {
      final repo = _MockCompletions();
      when(() => repo.listRequests(companyA)).thenAnswer((_) async => [pending]);
      when(() => repo.review(pending, approve: true)).thenAnswer(
        (_) async => CompletionRequest(
          id: 'r1',
          departureId: 'd1',
          tourTitle: 'Göksun',
          departureAt: pending.departureAt,
          guideName: 'Rıza',
          status: CompletionStatus.approved,
          createdAt: pending.createdAt,
        ),
      );
      final cubit = CompletionsCubit(companyId: companyA, repository: repo);
      await cubit.load();
      expect(cubit.state.pending, hasLength(1));

      final result = await cubit.review(pending, approve: true);

      expect(result.isSuccess, isTrue);
      expect(cubit.state.pending, isEmpty);
      expect(cubit.state.reviewed.single.status, CompletionStatus.approved);
      expect(cubit.state.busyRequestId, isNull);
      await cubit.close();
    });

    test('zaten sonuçlanmış talep hatası', () async {
      final repo = _MockCompletions();
      when(() => repo.listRequests(companyA)).thenAnswer((_) async => [pending]);
      when(
        () => repo.review(pending, approve: false),
      ).thenThrow(const PanelFailure(PanelFailureReason.alreadyReviewed));
      final cubit = CompletionsCubit(companyId: companyA, repository: repo);
      await cubit.load();

      final result = await cubit.review(pending, approve: false);

      expect(result.failure, PanelFailureReason.alreadyReviewed);
      expect(cubit.state.pending, hasLength(1));
      await cubit.close();
    });
  });
}
