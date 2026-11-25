part of 'my_tickets_cubit.dart';

enum MyTicketsStatus { loading, ready, failure }

final class MyTicketsState extends Equatable {
  const MyTicketsState({
    this.status = MyTicketsStatus.loading,
    this.tickets = const [],
    this.isRefreshing = false,
    this.isStale = false,
    this.failure,
  });

  final MyTicketsStatus status;
  final List<Ticket> tickets;
  final bool isRefreshing;

  /// Sunucuya ulaşılamadı; cihazdaki liste gösteriliyor.
  final bool isStale;
  final TicketFailureReason? failure;

  /// Geçerli biletler, en yakın kalkış önce.
  List<Ticket> get upcoming =>
      tickets.where((ticket) => ticket.isActive).toList()
        ..sort((left, right) => left.departureAt.compareTo(right.departureAt));

  /// İptal edilen, tamamlanan veya katılınmayan biletler, en yeni önce.
  List<Ticket> get past =>
      tickets.where((ticket) => !ticket.isActive).toList()
        ..sort((left, right) => right.departureAt.compareTo(left.departureAt));

  MyTicketsState copyWith({MyTicketsStatus? status, List<Ticket>? tickets, bool? isRefreshing}) =>
      MyTicketsState(
        status: status ?? this.status,
        tickets: tickets ?? this.tickets,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isStale: isStale,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, tickets, isRefreshing, isStale, failure];
}
