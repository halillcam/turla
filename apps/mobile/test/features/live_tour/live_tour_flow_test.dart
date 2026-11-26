import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/core/constants/strings.dart';
import 'package:turla_mobile/core/di/injection.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/announcement.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/live_tour_failure.dart';
import 'package:turla_mobile/features/live_tour/domain/repositories/announcement_repository.dart';
import 'package:turla_mobile/features/live_tour/presentation/cubit/announcements_cubit.dart';
import 'package:turla_mobile/features/live_tour/presentation/cubit/chat_cubit.dart';
import 'package:turla_mobile/features/live_tour/presentation/screens/announcements_screen.dart';
import 'package:turla_mobile/features/live_tour/presentation/screens/chat_screen.dart';
import 'package:turla_mobile/features/live_tour/presentation/widgets/active_tour_view.dart';
import 'package:turla_mobile/features/live_tour/presentation/widgets/chat_message_bubble.dart';

import '../../helpers/live_tour_fixtures.dart';

class _FakeAnnouncements implements AnnouncementRepository {
  final List<Announcement> items = [
    Announcement(id: 'a1', body: 'Mola 10 dakika', createdAt: baseTime),
  ];
  LiveTourFailure? sendError;

  @override
  Future<List<Announcement>> fetchAnnouncements(String departureId) async => items;

  @override
  Future<Announcement> sendAnnouncement(String departureId, String body) async {
    final error = sendError;
    if (error != null) throw error;
    return Announcement(id: 'a2', body: body, createdAt: baseTime.add(const Duration(hours: 1)));
  }
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  late FakeChatRepository chat;
  late _FakeAnnouncements announcements;

  setUpAll(() => initializeDateFormatting('tr_TR'));

  setUp(() {
    chat = FakeChatRepository(
      pages: [
        [
          messageWith(id: 'g', senderName: 'Selin Rehber', role: UserRole.guide, body: 'Hoş geldiniz'),
          messageWith(id: 'me', senderId: 'me', senderName: 'Ben', body: 'Teşekkürler'),
        ],
      ],
    );
    announcements = _FakeAnnouncements();
    getIt
      ..registerFactory<ChatCubit>(() => ChatCubit(chat))
      ..registerFactory<AnnouncementsCubit>(() => AnnouncementsCubit(announcements));
  });

  tearDown(() => getIt.reset());

  testWidgets('sohbet: rehber etiketi, "Sen" etiketi; yazınca mesaj eklenir ve kutu temizlenir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const ChatScreen(departureId: 'dep-1', args: ChatScreenArgs(canWrite: true))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selin Rehber · ${AppStrings.senderGuideTag}'), findsOneWidget);
    expect(find.text(AppStrings.you), findsOneWidget);
    expect(find.text(AppStrings.chatReadOnly), findsNothing);

    await tester.enterText(find.byType(TextField), 'Otobüs nerede?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(chat.sent, ['Otobüs nerede?']);
    expect(find.text('Otobüs nerede?'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('sohbet: Realtime ile gelen mesaj ekranda belirir', (tester) async {
    await tester.pumpWidget(
      _wrap(const ChatScreen(departureId: 'dep-1', args: ChatScreenArgs(canWrite: true))),
    );
    await tester.pumpAndSettle();
    chat.realtime.add(messageWith(id: 'yeni', minute: 5, body: 'Ben de geliyorum'));
    await tester.pumpAndSettle();
    expect(find.text('Ben de geliyorum'), findsOneWidget);
  });

  testWidgets('sohbet: yazma kapalıysa salt okunur bandı, yazı kutusu yok', (tester) async {
    await tester.pumpWidget(_wrap(const ChatScreen(departureId: 'dep-1')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.chatReadOnly), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ChatMessageBubble), findsNWidgets(2));
  });

  testWidgets('sohbet: hız sınırında hata mesajı görünür', (tester) async {
    chat.sendError = const LiveTourFailure(LiveTourFailureReason.rateLimited);
    await tester.pumpWidget(
      _wrap(const ChatScreen(departureId: 'dep-1', args: ChatScreenArgs(canWrite: true))),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'çok hızlı');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.errorChatRateLimited), findsOneWidget);
  });

  testWidgets('duyurular: rehber alıcı sayısını görür, gönderince listeye eklenir', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AnnouncementsScreen(
          departureId: 'dep-1',
          args: AnnouncementsScreenArgs(canSend: true, recipientCount: 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('12'), findsOneWidget);
    expect(find.text('Mola 10 dakika'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Otobüse dönüyoruz');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Otobüse dönüyoruz'), findsOneWidget);
    expect(find.text(AppStrings.announcementSent), findsOneWidget);
  });

  testWidgets('duyurular: müşteri sadece okur', (tester) async {
    await tester.pumpWidget(_wrap(const AnnouncementsScreen(departureId: 'dep-1')));
    await tester.pumpAndSettle();
    expect(find.text('Mola 10 dakika'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('aktif tur: okutulmuş yolcu rehberi arama düğmesini, sohbet/duyuru düğmelerini görür', (
    tester,
  ) async {
    var chatOpened = false;
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: ActiveTourView(
            tour: activeTourWith(
              lastAnnouncement: Announcement(id: 'a', body: 'Toplanma 14:00', createdAt: baseTime),
            ),
            onOpenChat: () => chatOpened = true,
            onOpenAnnouncements: () {},
          ),
        ),
      ),
    );
    expect(find.text('Selin Rehber'), findsOneWidget);
    expect(find.byTooltip(AppStrings.callGuide), findsOneWidget);
    expect(find.text('Toplanma 14:00'), findsOneWidget);
    expect(find.text(AppStrings.unlocksAfterCheckIn), findsNothing);
    await tester.tap(find.text(AppStrings.tourChat));
    expect(chatOpened, isTrue);
  });

  testWidgets('aktif tur: QR okutulmadan sohbet kilitli, telefon yoksa arama düğmesi yok', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: ActiveTourView(
            tour: activeTourWith(ticketStatus: TicketStatus.paid, chatOpen: false, guidePhone: null),
            onOpenChat: () {},
            onOpenAnnouncements: () {},
          ),
        ),
      ),
    );
    expect(find.text(AppStrings.unlocksAfterCheckIn), findsOneWidget);
    expect(find.text(AppStrings.tourChat), findsNothing);
    expect(find.byTooltip(AppStrings.callGuide), findsNothing);
  });
}
