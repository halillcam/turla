import 'package:flutter_test/flutter_test.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/live_tour_failure.dart';
import 'package:turla_mobile/features/live_tour/domain/repositories/chat_repository.dart';
import 'package:turla_mobile/features/live_tour/presentation/cubit/chat_cubit.dart';

import '../../helpers/live_tour_fixtures.dart';

void main() {
  late FakeChatRepository repository;
  late ChatCubit cubit;

  setUp(() {
    repository = FakeChatRepository(
      pages: [
        [messageWith(id: 'm2', minute: 2), messageWith(id: 'm1', minute: 1)],
      ],
    );
    cubit = ChatCubit(repository);
  });

  tearDown(() => cubit.close());

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('açılınca son sayfa gelir ve Realtime dinlenmeye başlanır', () async {
    await cubit.start('dep-1', canWrite: true);
    expect(cubit.state.status, ChatStatus.ready);
    expect(cubit.state.messages.map((m) => m.id), ['m2', 'm1']);
    expect(cubit.state.hasMore, isFalse);
    expect(repository.realtime.hasListener, isTrue);
  });

  test('Realtime ile gelen mesaj en üste (en yeni) eklenir, tekrarlar atılır', () async {
    await cubit.start('dep-1', canWrite: true);
    repository.realtime.add(messageWith(id: 'm3', minute: 3));
    repository.realtime.add(messageWith(id: 'm3', minute: 3));
    await flush();
    expect(cubit.state.messages.map((m) => m.id), ['m3', 'm2', 'm1']);
  });

  test('gönderilen mesaj listeye eklenir; aynı mesaj Realtime ile gelince çiftlenmez', () async {
    await cubit.start('dep-1', canWrite: true);
    await cubit.send('  Otobüs nerede?  ');
    expect(repository.sent, ['Otobüs nerede?']);
    expect(cubit.state.sentCount, 1);
    repository.realtime.add(cubit.state.messages.first);
    await flush();
    expect(cubit.state.messages.where((m) => m.id == 'sent-1'), hasLength(1));
  });

  test('boş mesaj ve salt okunur sohbette gönderim yapılmaz', () async {
    await cubit.start('dep-1', canWrite: false);
    await cubit.send('Merhaba');
    await cubit.send('   ');
    expect(repository.sent, isEmpty);
  });

  test('sunucu yazmayı reddederse (tur bitti) yazı kutusu kapanır', () async {
    repository.sendError = const LiveTourFailure(LiveTourFailureReason.notAllowed);
    await cubit.start('dep-1', canWrite: true);
    await cubit.send('Merhaba');
    expect(cubit.state.canWrite, isFalse);
    expect(cubit.state.actionFailure, LiveTourFailureReason.notAllowed);
  });

  test('mesaj sınırı aşılınca (rate_limited) yazma açık kalır, hata gösterilir', () async {
    repository.sendError = const LiveTourFailure(LiveTourFailureReason.rateLimited);
    await cubit.start('dep-1', canWrite: true);
    await cubit.send('Merhaba');
    expect(cubit.state.canWrite, isTrue);
    expect(cubit.state.actionFailure, LiveTourFailureReason.rateLimited);
    cubit.clearActionFailure();
    expect(cubit.state.actionFailure, isNull);
  });

  test('dolu sayfa gelince önceki mesajlar en eskinin zamanından istenir', () async {
    final full = List.generate(
      ChatRepository.pageSize,
      (i) => messageWith(id: 'p$i', minute: 1000 - i),
    );
    repository.pages = [
      full,
      [messageWith(id: 'old', minute: 1)],
    ];
    await cubit.start('dep-1', canWrite: true);
    expect(cubit.state.hasMore, isTrue);
    await cubit.loadMore();
    expect(repository.lastBefore, full.last.createdAt);
    expect(cubit.state.messages.last.id, 'old');
    expect(cubit.state.hasMore, isFalse);
  });

  test('kendi mesajını siler; başkasınınki silinemez görünür', () async {
    repository.pages = [
      [messageWith(id: 'mine', senderId: 'me'), messageWith(id: 'theirs')],
    ];
    await cubit.start('dep-1', canWrite: true);
    final mine = cubit.state.messages.firstWhere((m) => m.id == 'mine');
    final theirs = cubit.state.messages.firstWhere((m) => m.id == 'theirs');
    expect(cubit.state.canDelete(mine), isTrue);
    expect(cubit.state.canDelete(theirs), isFalse);
    await cubit.delete(mine);
    expect(repository.deleted, ['mine']);
    expect(cubit.state.messages.map((m) => m.id), ['theirs']);
  });

  test('ilk yükleme hatası failure, tekrar dene ile düzelir', () async {
    repository.pageError = const LiveTourFailure(LiveTourFailureReason.network);
    await cubit.start('dep-1', canWrite: true);
    expect(cubit.state.status, ChatStatus.failure);
    repository.pageError = null;
    await cubit.retry();
    expect(cubit.state.status, ChatStatus.ready);
  });

  test('ekran kapanınca (cubit kapanınca) Realtime aboneliği biter', () async {
    await cubit.start('dep-1', canWrite: true);
    await cubit.close();
    expect(repository.realtime.hasListener, isFalse);
  });
}
