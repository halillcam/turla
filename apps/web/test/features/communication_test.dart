import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_web/core/bloc/load_status.dart';
import 'package:turla_web/core/constants/strings.dart';
import 'package:turla_web/core/di/injection.dart';
import 'package:turla_web/core/errors/panel_failure.dart';
import 'package:turla_web/features/announcements/domain/entities/company_announcement.dart';
import 'package:turla_web/features/announcements/domain/repositories/company_announcement_repository.dart';
import 'package:turla_web/features/announcements/presentation/cubit/company_announcements_cubit.dart';
import 'package:turla_web/features/chat/domain/entities/panel_chat_message.dart';
import 'package:turla_web/features/chat/domain/repositories/panel_chat_repository.dart';
import 'package:turla_web/features/chat/presentation/cubit/panel_chat_cubit.dart';
import 'package:turla_web/features/chat/presentation/widgets/departure_chat_dialog.dart';
import 'package:turla_web/features/companies/domain/repositories/company_repository.dart';
import 'package:turla_web/features/feedback/domain/entities/feedback_item.dart';
import 'package:turla_web/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:turla_web/features/feedback/presentation/cubit/feedback_cubit.dart';
import 'package:turla_web/features/tours/domain/entities/departure.dart';

import '../helpers/fixtures.dart';

class _MockChat extends Mock implements PanelChatRepository {}

class _MockAnnouncements extends Mock implements CompanyAnnouncementRepository {}

class _MockCompanies extends Mock implements CompanyRepository {}

class _MockFeedback extends Mock implements FeedbackRepository {}

final DateTime _t = DateTime.utc(2026, 12, 1, 8);

PanelChatMessage _msg(String id, {UserRole role = UserRole.customer, int minute = 0}) =>
    PanelChatMessage(
      id: id,
      senderId: 's-$id',
      senderName: 'Kişi $id',
      senderRole: role,
      body: 'Mesaj $id',
      createdAt: _t.add(Duration(minutes: minute)),
    );

FeedbackItem _feedback(String id) => FeedbackItem(
  id: id,
  companyId: companyA,
  companyName: 'Maraş Turizm',
  authorName: 'Admin Ali',
  title: 'Öneri $id',
  body: 'Rapor ekranı',
  status: FeedbackStatus.open,
  createdAt: _t,
);

Departure _departure(DepartureStatus status) => Departure(
  id: 'dep-1',
  tourId: 'tour-1',
  departureAt: _t,
  capacity: 10,
  seatsLeft: 5,
  status: status,
);

void main() {
  setUpAll(() {
    initializeDateFormatting('tr_TR');
    registerFallbackValue(_feedback('x'));
    registerFallbackValue(FeedbackStatus.open);
  });

  group('PanelChatCubit', () {
    late _MockChat chat;
    setUp(() => chat = _MockChat());

    test('yüklenir; gönderilen mesaj listenin başına eklenir, liste yeniden çekilmez', () async {
      when(() => chat.listMessages('dep-1')).thenAnswer((_) async => [_msg('a')]);
      when(() => chat.send('dep-1', 'Firma burada')).thenAnswer((_) async => _msg('b', minute: 1));
      final cubit = PanelChatCubit(departureId: 'dep-1', canWrite: true, repository: chat);
      await cubit.load();
      final result = await cubit.send('Firma burada');
      expect(result.isSuccess, isTrue);
      expect(cubit.state.messages.map((m) => m.id), ['b', 'a']);
      verify(() => chat.listMessages('dep-1')).called(1);
    });

    test('salt okunur sohbette gönderim yapılmaz', () async {
      final cubit = PanelChatCubit(departureId: 'dep-1', canWrite: false, repository: chat);
      await cubit.send('Merhaba');
      verifyNever(() => chat.send(any(), any()));
    });

    test('silinen mesaj listeden çıkar; hata olursa liste aynen kalır', () async {
      when(() => chat.listMessages('dep-1')).thenAnswer((_) async => [_msg('a'), _msg('b')]);
      when(() => chat.delete('a')).thenAnswer((_) async {});
      when(() => chat.delete('b')).thenThrow(const PanelFailure(PanelFailureReason.network));
      final cubit = PanelChatCubit(departureId: 'dep-1', canWrite: true, repository: chat);
      await cubit.load();
      await cubit.delete(_msg('a'));
      final failed = await cubit.delete(_msg('b'));
      expect(failed.failure, PanelFailureReason.network);
      expect(cubit.state.messages.map((m) => m.id), ['b']);
    });

    test('dolu sayfada önceki mesajlar en eskinin zamanından istenir', () async {
      final page = List.generate(PanelChatRepository.pageSize, (i) => _msg('p$i', minute: 500 - i));
      when(() => chat.listMessages('dep-1')).thenAnswer((_) async => page);
      when(
        () => chat.listMessages('dep-1', before: page.last.createdAt),
      ).thenAnswer((_) async => [_msg('eski')]);
      final cubit = PanelChatCubit(departureId: 'dep-1', canWrite: true, repository: chat);
      await cubit.load();
      expect(cubit.state.hasMore, isTrue);
      await cubit.loadMore();
      expect(cubit.state.messages.last.id, 'eski');
      expect(cubit.state.hasMore, isFalse);
    });
  });

  group('Sohbet penceresi', () {
    late _MockChat chat;

    setUp(() {
      chat = _MockChat();
      getIt.registerFactoryParam<PanelChatCubit, String, bool>(
        (departureId, canWrite) =>
            PanelChatCubit(departureId: departureId, canWrite: canWrite, repository: chat),
      );
    });

    tearDown(() => getIt.reset());

    Future<void> open(WidgetTester tester, DepartureStatus status) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDepartureChatDialog(context, departure: _departure(status)),
              child: const Text('aç'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
    }

    testWidgets('açık tarihte rehber etiketi görünür ve firma mesaj yazabilir', (tester) async {
      when(() => chat.listMessages('dep-1')).thenAnswer(
        (_) async => [_msg('g', role: UserRole.guide)],
      );
      await open(tester, DepartureStatus.scheduled);
      expect(find.text('Kişi g · ${AppStrings.chatGuideTag}'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(AppStrings.chatReadOnlyPanel), findsNothing);
    });

    testWidgets('bitmiş tarihte mesajlar okunur, yazı kutusu yok', (tester) async {
      when(() => chat.listMessages('dep-1')).thenAnswer((_) async => [_msg('a')]);
      await open(tester, DepartureStatus.completed);
      expect(find.text('Mesaj a'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(AppStrings.chatReadOnlyPanel), findsOneWidget);
    });
  });

  group('CompanyAnnouncementsCubit', () {
    late _MockAnnouncements announcements;
    late _MockCompanies companies;

    setUp(() {
      announcements = _MockAnnouncements();
      companies = _MockCompanies();
      when(() => companies.listCompanies()).thenAnswer((_) async => [activeCompany]);
    });

    test('super admin: hedef firmalar yüklenir, yayınlanan duyuru başa eklenir', () async {
      when(() => announcements.list()).thenAnswer((_) async => []);
      when(
        () => announcements.create(title: 'Bakım', body: 'Pazar gece', companyId: null),
      ).thenAnswer(
        (_) async => CompanyAnnouncement(id: 'a1', title: 'Bakım', body: 'Pazar gece', createdAt: _t),
      );
      final cubit = CompanyAnnouncementsCubit(
        companyId: null,
        repository: announcements,
        companyRepository: companies,
      );
      await cubit.load();
      expect(cubit.canManage, isTrue);
      expect(cubit.state.companies, [activeCompany]);
      await cubit.publish(title: 'Bakım', body: 'Pazar gece');
      expect(cubit.state.announcements.single.isForAllCompanies, isTrue);
    });

    test('firma alanı: sadece okur, firma listesi çekilmez', () async {
      when(() => announcements.list(companyId: companyA)).thenAnswer((_) async => []);
      final cubit = CompanyAnnouncementsCubit(
        companyId: companyA,
        repository: announcements,
        companyRepository: companies,
      );
      await cubit.load();
      expect(cubit.canManage, isFalse);
      expect(cubit.state.status, LoadStatus.ready);
      verifyNever(() => companies.listCompanies());
    });
  });

  group('FeedbackCubit', () {
    late _MockFeedback feedback;
    setUp(() => feedback = _MockFeedback());

    test('firma admini gönderir, liste başına eklenir', () async {
      when(() => feedback.list(companyId: companyA)).thenAnswer((_) async => []);
      when(
        () => feedback.send(companyId: companyA, title: 'Öneri', body: 'Rapor'),
      ).thenAnswer((_) async => _feedback('f1'));
      final cubit = FeedbackCubit(companyId: companyA, repository: feedback);
      await cubit.load();
      final result = await cubit.send(title: 'Öneri', body: 'Rapor');
      expect(result.isSuccess, isTrue);
      expect(cubit.state.items.single.id, 'f1');
    });

    test('super admin durumu değiştirir; firma seçilmeden gönderim yapılamaz', () async {
      when(() => feedback.list()).thenAnswer((_) async => [_feedback('f1')]);
      when(
        () => feedback.setStatus(any(), FeedbackStatus.resolved),
      ).thenAnswer((_) async => _feedback('f1').withStatus(FeedbackStatus.resolved));
      final cubit = FeedbackCubit(companyId: null, repository: feedback);
      await cubit.load();
      await cubit.setStatus(cubit.state.items.single, FeedbackStatus.resolved);
      expect(cubit.state.items.single.status, FeedbackStatus.resolved);
      final denied = await cubit.send(title: 'x', body: 'y');
      expect(denied.failure, PanelFailureReason.notAllowed);
    });
  });
}
