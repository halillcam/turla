import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/live_tour/data/datasources/live_tour_remote_data_source.dart';
import 'package:turla_mobile/features/live_tour/data/models/live_tour_models.dart';
import 'package:turla_mobile/features/live_tour/data/repositories/live_tour_repository_impl.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/active_tour.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/announcement.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/chat_message.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/live_tour_failure.dart';

import '../../helpers/live_tour_fixtures.dart';

class _FakeRemote implements LiveTourRemoteDataSource {
  @override
  String? currentUserId = 'me';
  Object? error;
  String? sentBody;
  int? lastLimit;
  final StreamController<ChatMessage> realtime = StreamController.broadcast();

  Future<T> _run<T>(T value) async {
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<ActiveTour> fetchActiveTour(String departureId) => _run(activeTourWith());

  @override
  Future<List<ChatMessage>> fetchMessages(
    String departureId, {
    DateTime? before,
    required int limit,
  }) {
    lastLimit = limit;
    return _run([messageWith(id: 'm1')]);
  }

  @override
  Future<ChatMessage> sendMessage(String departureId, String body) {
    sentBody = body;
    return _run(messageWith(id: 'new', body: body));
  }

  @override
  Future<void> deleteMessage(String messageId) => _run(null);

  @override
  Stream<ChatMessage> watchMessages(String departureId) => realtime.stream;

  @override
  Future<List<Announcement>> fetchAnnouncements(String departureId) => _run(const []);

  @override
  Future<Announcement> sendAnnouncement(String departureId, String body) {
    sentBody = body;
    return _run(Announcement(id: 'a1', body: body, createdAt: baseTime));
  }
}

void main() {
  late _FakeRemote remote;
  late LiveTourRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    repository = LiveTourRepositoryImpl(remote);
  });

  Matcher failureWith(LiveTourFailureReason reason) =>
      throwsA(isA<LiveTourFailure>().having((f) => f.reason, 'reason', reason));

  test('mesaj kırpılarak gönderilir; sayfa boyutu 50', () async {
    await repository.send('dep-1', '  selam  ');
    await repository.fetchPage('dep-1');
    expect(remote.sentBody, 'selam');
    expect(remote.lastLimit, 50);
  });

  test('2000 karakterden uzun mesaj sunucuya gitmeden reddedilir', () async {
    await expectLater(
      repository.send('dep-1', 'a' * (ChatMessage.maxLength + 1)),
      failureWith(LiveTourFailureReason.messageTooLong),
    );
    expect(remote.sentBody, isNull);
  });

  test('1000 karakterden uzun duyuru reddedilir', () async {
    await expectLater(
      repository.sendAnnouncement('dep-1', 'a' * (Announcement.maxLength + 1)),
      failureWith(LiveTourFailureReason.messageTooLong),
    );
  });

  test('giriş yoksa notSignedIn', () async {
    remote.currentUserId = null;
    await expectLater(repository.fetch('dep-1'), failureWith(LiveTourFailureReason.notSignedIn));
  });

  test(
    'sunucu kodları eşlenir: rate_limited, RLS, kısıt, not_allowed, departure_not_active',
    () async {
      final cases = {
        const PostgrestException(message: 'rate_limited', code: 'P0001'):
            LiveTourFailureReason.rateLimited,
        const PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ): LiveTourFailureReason.notAllowed,
        const PostgrestException(message: 'violates check constraint', code: '23514'):
            LiveTourFailureReason.messageTooLong,
        const PostgrestException(message: 'not_allowed', code: 'P0001'):
            LiveTourFailureReason.notAllowed,
        const PostgrestException(message: 'departure_not_active', code: 'P0001'):
            LiveTourFailureReason.departureNotActive,
        const PostgrestException(message: 'beklenmeyen', code: 'XX000'):
            LiveTourFailureReason.unknown,
      };
      for (final entry in cases.entries) {
        remote.error = entry.key;
        await expectLater(repository.send('dep-1', 'x'), failureWith(entry.value));
      }
    },
  );

  test('ağ hatası network', () async {
    remote.error = ClientException('yok');
    await expectLater(repository.fetchPage('dep-1'), failureWith(LiveTourFailureReason.network));
    remote.error = TimeoutException('yavaş');
    await expectLater(
      repository.fetchAnnouncements('dep-1'),
      failureWith(LiveTourFailureReason.network),
    );
  });

  test('Realtime akışı uzak kaynaktan geçer, dinleme bitince kapanır', () async {
    final received = <String>[];
    final subscription = repository.watch('dep-1').listen((m) => received.add(m.id));
    remote.realtime.add(messageWith(id: 'live'));
    await Future<void>.delayed(Duration.zero);
    expect(received, ['live']);
    await subscription.cancel();
    expect(remote.realtime.hasListener, isFalse);
  });

  test('participant_departure_info yanıtı çözülür', () {
    final tour = ActiveTourModel.fromJson({
      'departure_id': 'dep-1',
      'tour_title': 'Göksun Turu',
      'departure_at': '2026-12-01T08:00:00+00:00',
      'status': 'scheduled',
      'ticket_status': 'paid',
      'bus_plate': '46 S 5',
      'company_name': 'Maraş Doğa',
      'guide_name': 'Selin',
      'guide_phone': '0532',
      'chat_open': false,
      'program': [
        {
          'day_no': 1,
          'title': 'Göksun',
          'activities': ['Kahvaltı'],
        },
      ],
      'last_announcement': null,
    });
    expect(tour.ticketStatus, TicketStatus.paid);
    expect(tour.isCheckedIn, isFalse);
    expect(tour.chatOpen, isFalse);
    expect(tour.program.single.activities, ['Kahvaltı']);
    expect(tour.lastAnnouncement, isNull);
  });

  test('Realtime mesaj satırı çözülür (rol yoksa yolcu)', () {
    final message = ChatMessageModel.fromRow({
      'id': 'm',
      'departure_id': 'dep-1',
      'sender_id': 's',
      'sender_name': 'Rıza',
      'sender_role': 'guide',
      'body': 'Mola',
      'created_at': '2026-12-01T08:00:00+00:00',
    });
    expect(message.senderRole, UserRole.guide);
    expect(message.isStaff, isTrue);
  });
}
