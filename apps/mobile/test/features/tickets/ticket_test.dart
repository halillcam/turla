import 'package:flutter_test/flutter_test.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/tickets/data/models/ticket_model.dart';
import 'package:turla_mobile/features/tickets/data/repositories/ticket_repository_impl.dart';
import 'package:turla_mobile/features/tickets/domain/entities/ticket_failure.dart';
import 'package:turla_mobile/features/tickets/presentation/cubit/my_tickets_cubit.dart';
import 'package:turla_mobile/features/tickets/presentation/utils/ticket_failure_message.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('Ticket', () {
    final departure = DateTime.utc(2026, 12, 5, 7);

    test('kalkıştan 1 saat öncesine kadar iptal edilebilir, sonrası edilemez', () {
      final ticket = ticketWith(departureAt: departure);
      expect(ticket.canCancelAt(departure.subtract(const Duration(hours: 2))), isTrue);
      expect(ticket.canCancelAt(departure.subtract(const Duration(minutes: 61))), isTrue);
      expect(ticket.canCancelAt(departure.subtract(const Duration(hours: 1))), isFalse);
      expect(ticket.canCancelAt(departure.subtract(const Duration(minutes: 30))), isFalse);
    });

    test('kullanılmış, iptal edilmiş veya tamamlanmış tarihli bilet iptal edilemez', () {
      final early = departure.subtract(const Duration(days: 1));
      expect(ticketWith(status: TicketStatus.checkedIn).canCancelAt(early), isFalse);
      expect(ticketWith(status: TicketStatus.cancelled).canCancelAt(early), isFalse);
      expect(
        ticketWith(departureStatus: DepartureStatus.finishRequested).canCancelAt(early),
        isFalse,
      );
    });

    test('iptal sonrası tam iade; ücretsiz turda iade yok', () {
      final at = DateTime.utc(2026, 12, 1);
      final cancelled = ticketWith().cancelled(at);
      expect(cancelled.status, TicketStatus.cancelled);
      expect(cancelled.cancelledAt, at);
      expect(cancelled.refundAmount, 1850);
      expect(ticketWith(pricePaid: 0).cancelled(at).refundAmount, isNull);
    });

    test('aktif bilet: geçerli durum ve tamamlanmamış tarih', () {
      expect(ticketWith().isActive, isTrue);
      expect(ticketWith(status: TicketStatus.checkedIn).isActive, isTrue);
      expect(ticketWith(status: TicketStatus.cancelled).isActive, isFalse);
      expect(ticketWith(status: TicketStatus.noShow).isActive, isFalse);
      expect(ticketWith(departureStatus: DepartureStatus.completed).isActive, isFalse);
    });
  });

  test('TicketModel sunucu satırını okur ve önbellek biçimi aynen geri okunur', () {
    final row = {
      'id': 't1',
      'qr_token': 'abc',
      'status': 'cancelled',
      'passenger_name': 'Ali Veli',
      'price_paid': 750.5,
      'created_at': '2026-11-20T10:00:00Z',
      'cancelled_at': '2026-11-21T10:00:00Z',
      'departure': {
        'id': 'd1',
        'departure_at': '2026-12-05T07:00:00Z',
        'status': 'scheduled',
        'bus_plate': '46 ABC 101',
        'driver_name': null,
        'driver_phone': null,
        'tour': {
          'id': 'tour1',
          'title': 'Nemrut',
          'image_url': null,
          'company': {'name': 'Demo', 'phone': '0344'},
        },
      },
      'payments': [
        {'type': 'payment', 'amount': 750.5},
        {'type': 'refund', 'amount': 750.5},
      ],
    };
    final ticket = TicketModel.fromRow(row);
    expect(ticket.status, TicketStatus.cancelled);
    expect(ticket.refundAmount, 750.5);
    expect(ticket.tourTitle, 'Nemrut');
    expect(ticket.companyPhone, '0344');
    expect(ticket.departureAt, DateTime.utc(2026, 12, 5, 7));
    expect(TicketModel.fromRow(TicketModel.toRow(ticket)), ticket);
  });

  test('sunucu hata kodları doğru türe çevrilir', () {
    const codes = {
      'only_customers_can_book': TicketFailureReason.onlyCustomersCanBook,
      'departure_not_found': TicketFailureReason.departureNotFound,
      'tour_not_available': TicketFailureReason.tourNotAvailable,
      'departure_not_bookable': TicketFailureReason.departureNotBookable,
      'already_has_ticket': TicketFailureReason.alreadyHasTicket,
      'no_seats_left': TicketFailureReason.noSeatsLeft,
      'ticket_not_found': TicketFailureReason.ticketNotFound,
      'not_allowed': TicketFailureReason.notAllowed,
      'ticket_not_cancellable': TicketFailureReason.ticketNotCancellable,
      'cancellation_window_closed': TicketFailureReason.cancellationWindowClosed,
    };
    codes.forEach((code, reason) => expect(TicketErrorMapper.fromPostgrest('P0001', code), reason));
    expect(
      TicketErrorMapper.fromPostgrest('42501', 'permission denied'),
      TicketFailureReason.notAllowed,
    );
    expect(TicketErrorMapper.fromPostgrest('XX000', 'bilinmeyen'), TicketFailureReason.unknown);
  });

  test('her hata türünün ayrı bir Türkçe mesajı var', () {
    final messages = TicketFailureReason.values.map((reason) => reason.message).toList();
    expect(messages.every((message) => message.isNotEmpty), isTrue);
    expect(messages.toSet().length, messages.length);
  });

  test('Turlarım: yaklaşanlar en yakın tarih önce, geçmişler en yeni önce', () {
    final state = MyTicketsState(
      status: MyTicketsStatus.ready,
      tickets: [
        ticketWith(id: 'late', departureAt: DateTime.utc(2026, 12, 20)),
        ticketWith(id: 'soon', departureAt: DateTime.utc(2026, 12, 2)),
        ticketWith(
          id: 'old',
          status: TicketStatus.completed,
          departureAt: DateTime.utc(2026, 10, 1),
        ),
        ticketWith(
          id: 'cancel',
          status: TicketStatus.cancelled,
          departureAt: DateTime.utc(2026, 11, 1),
        ),
      ],
    );
    expect(state.upcoming.map((ticket) => ticket.id), ['soon', 'late']);
    expect(state.past.map((ticket) => ticket.id), ['cancel', 'old']);
  });
}
