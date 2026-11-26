import 'dart:async';

import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/active_tour.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/announcement.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/chat_message.dart';
import 'package:turla_mobile/features/live_tour/domain/entities/live_tour_failure.dart';
import 'package:turla_mobile/features/live_tour/domain/repositories/chat_repository.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour_program_day.dart';

final DateTime baseTime = DateTime.utc(2026, 12, 1, 8);

ChatMessage messageWith({
  required String id,
  int minute = 0,
  String senderId = 'other',
  String senderName = 'Ayşe Kaya',
  UserRole role = UserRole.customer,
  String body = 'Merhaba',
}) => ChatMessage(
  id: id,
  departureId: 'dep-1',
  senderId: senderId,
  senderName: senderName,
  senderRole: role,
  body: body,
  createdAt: baseTime.add(Duration(minutes: minute)),
);

ActiveTour activeTourWith({
  TicketStatus ticketStatus = TicketStatus.checkedIn,
  bool chatOpen = true,
  String? guidePhone = '0532 000 11 22',
  Announcement? lastAnnouncement,
}) => ActiveTour(
  departureId: 'dep-1',
  tourTitle: 'Göksun Turu',
  departureAt: baseTime,
  departureStatus: DepartureStatus.scheduled,
  ticketStatus: ticketStatus,
  companyName: 'Maraş Doğa',
  chatOpen: chatOpen,
  guideName: 'Selin Rehber',
  guidePhone: guidePhone,
  busPlate: '46 S 5',
  lastAnnouncement: lastAnnouncement,
  program: const [
    TourProgramDay(dayNo: 1, title: 'Göksun', activities: ['Kahvaltı', 'Yürüyüş']),
  ],
);

/// Sahte sohbet deposu: sayfalar elle verilir, Realtime kanalı bir StreamController'dır.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({this.pages = const []});

  /// Sırayla dönen sayfalar (ilk sayfa, sonraki eski sayfalar).
  List<List<ChatMessage>> pages;
  int pageCalls = 0;
  DateTime? lastBefore;
  LiveTourFailure? sendError;
  LiveTourFailure? pageError;
  final List<String> deleted = [];
  final List<String> sent = [];
  final StreamController<ChatMessage> realtime = StreamController.broadcast();

  @override
  String? currentUserId = 'me';

  @override
  Future<List<ChatMessage>> fetchPage(String departureId, {DateTime? before}) async {
    lastBefore = before;
    final error = pageError;
    if (error != null) throw error;
    final index = pageCalls++;
    return index < pages.length ? pages[index] : const [];
  }

  @override
  Future<ChatMessage> send(String departureId, String body) async {
    final error = sendError;
    if (error != null) throw error;
    sent.add(body);
    return messageWith(id: 'sent-${sent.length}', senderId: 'me', body: body, minute: 100);
  }

  @override
  Future<void> delete(String messageId) async => deleted.add(messageId);

  @override
  Stream<ChatMessage> watch(String departureId) => realtime.stream;
}
