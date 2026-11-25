import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/tickets/data/datasources/ticket_local_data_source.dart';
import 'package:turla_mobile/features/tickets/data/datasources/ticket_remote_data_source.dart';
import 'package:turla_mobile/features/tickets/data/repositories/ticket_repository_impl.dart';
import 'package:turla_mobile/features/tickets/domain/entities/ticket.dart';
import 'package:turla_mobile/features/tickets/domain/entities/ticket_failure.dart';

import '../../helpers/fixtures.dart';

class _FakeRemote implements TicketRemoteDataSource {
  @override
  String? currentUserId = 'user-1';
  List<Ticket> tickets = [ticketWith(id: 'server')];
  Ticket booked = ticketWith(id: 'new');
  DateTime cancelledAt = DateTime.utc(2026, 12, 1, 9);
  Object? error;
  int fetchCalls = 0;
  String? bookedName;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<List<Ticket>> fetchMyTickets(String userId) async {
    fetchCalls++;
    _throwIfNeeded();
    return tickets;
  }

  @override
  Future<Ticket> fetchTicket(String ticketId) async => booked;

  @override
  Future<String> bookTicket({required String departureId, required String passengerName}) async {
    _throwIfNeeded();
    bookedName = passengerName;
    return booked.id;
  }

  @override
  Future<DateTime> cancelTicket(String ticketId) async {
    _throwIfNeeded();
    return cancelledAt;
  }
}

class _FakeLocal implements TicketLocalDataSource {
  final Map<String, List<Ticket>> store = {};

  @override
  Future<List<Ticket>?> read(String userId) async => store[userId];

  @override
  Future<void> write(String userId, List<Ticket> tickets) async => store[userId] = tickets;
}

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late TicketRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repository = TicketRepositoryImpl(remoteDataSource: remote, localDataSource: local);
  });

  test('cihazdaki biletler istek atmadan okunur, kullanıcı bazında tutulur', () async {
    local.store['user-1'] = [ticketWith(id: 'cached')];
    local.store['user-2'] = [ticketWith(id: 'other')];

    final tickets = await repository.getCachedTickets();

    expect(tickets.single.id, 'cached');
    expect(remote.fetchCalls, 0);
  });

  test('giriş yoksa cihazdaki liste boş döner', () async {
    remote.currentUserId = null;
    local.store['user-1'] = [ticketWith()];
    expect(await repository.getCachedTickets(), isEmpty);
  });

  test('yenileme sunucudan çeker, cihaza yazar ve değişikliği yayar', () async {
    final changes = repository.changes.first;

    final tickets = await repository.refreshTickets();

    expect(tickets.single.id, 'server');
    expect(local.store['user-1']!.single.id, 'server');
    expect((await changes).single.id, 'server');
  });

  test('bilet alınca yeni bilet listenin başına eklenir', () async {
    local.store['user-1'] = [ticketWith(id: 'old')];

    final ticket = await repository.bookTicket(departureId: 'dep', passengerName: '  Ali Veli ');

    expect(ticket.id, 'new');
    expect(remote.bookedName, 'Ali Veli');
    expect(local.store['user-1']!.map((ticket) => ticket.id), ['new', 'old']);
  });

  test('iptal cihazdaki bileti günceller, tam iade yazılır, yeniden istek atılmaz', () async {
    local.store['user-1'] = [ticketWith(id: 'a'), ticketWith(id: 'b')];

    final cancelled = await repository.cancelTicket(ticketWith(id: 'a'));

    expect(cancelled.status, TicketStatus.cancelled);
    expect(cancelled.refundAmount, 1850);
    expect(cancelled.cancelledAt, remote.cancelledAt);
    expect(local.store['user-1']!.first, cancelled);
    expect(local.store['user-1']![1].status, TicketStatus.paid);
    expect(remote.fetchCalls, 0);
  });

  test('sunucu hata kodu TicketFailure olarak döner', () async {
    remote.error = const PostgrestException(message: 'no_seats_left', code: 'P0001');
    await expectLater(
      repository.bookTicket(departureId: 'dep', passengerName: 'Ali'),
      throwsA(
        isA<TicketFailure>().having((f) => f.reason, 'reason', TicketFailureReason.noSeatsLeft),
      ),
    );
    remote.error = const PostgrestException(message: 'cancellation_window_closed', code: 'P0001');
    await expectLater(
      repository.cancelTicket(ticketWith()),
      throwsA(
        isA<TicketFailure>().having(
          (f) => f.reason,
          'reason',
          TicketFailureReason.cancellationWindowClosed,
        ),
      ),
    );
  });

  test('ağ hatası network olarak döner, cihazdaki liste bozulmaz', () async {
    local.store['user-1'] = [ticketWith(id: 'cached')];
    remote.error = ClientException('bağlantı yok');

    await expectLater(
      repository.refreshTickets(),
      throwsA(isA<TicketFailure>().having((f) => f.reason, 'reason', TicketFailureReason.network)),
    );
    expect(local.store['user-1']!.single.id, 'cached');
  });

  test('giriş yapılmadan bilet alınamaz', () async {
    remote.currentUserId = null;
    await expectLater(
      repository.bookTicket(departureId: 'dep', passengerName: 'Ali'),
      throwsA(
        isA<TicketFailure>().having((f) => f.reason, 'reason', TicketFailureReason.notSignedIn),
      ),
    );
  });
}
