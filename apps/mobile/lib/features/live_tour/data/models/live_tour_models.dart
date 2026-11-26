import 'package:turla_core/turla_core.dart';

import '../../../tours/domain/entities/tour_program_day.dart';
import '../../domain/entities/active_tour.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/chat_message.dart';

/// Supabase satırı ↔ sohbet mesajı. Realtime yükü de aynı satır biçimindedir.
abstract final class ChatMessageModel {
  static const String columns =
      'id, departure_id, sender_id, sender_name, sender_role, body, created_at';

  static ChatMessage fromRow(Map<String, dynamic> row) => ChatMessage(
    id: row['id'] as String,
    departureId: row['departure_id'] as String,
    senderId: row['sender_id'] as String,
    senderName: row['sender_name'] as String,
    senderRole: UserRole.fromValue((row['sender_role'] as String?) ?? UserRole.customer.value),
    body: row['body'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}

abstract final class AnnouncementModel {
  static const String columns = 'id, body, created_at';

  static Announcement fromRow(Map<String, dynamic> row) => Announcement(
    id: (row['id'] as String?) ?? '',
    body: row['body'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}

/// `participant_departure_info` yanıtı.
abstract final class ActiveTourModel {
  static ActiveTour fromJson(Map<String, dynamic> json) {
    final last = json['last_announcement'] as Map<String, dynamic>?;
    final program = ((json['program'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (day) => TourProgramDay(
            dayNo: (day['day_no'] as num).toInt(),
            title: (day['title'] as String?) ?? '',
            activities: ((day['activities'] as List<dynamic>?) ?? const []).cast<String>(),
          ),
        )
        .toList();
    return ActiveTour(
      departureId: json['departure_id'] as String,
      tourTitle: json['tour_title'] as String,
      departureAt: DateTime.parse(json['departure_at'] as String),
      departureStatus: DepartureStatus.fromValue(json['status'] as String),
      ticketStatus: TicketStatus.fromValue(json['ticket_status'] as String),
      busPlate: json['bus_plate'] as String?,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      companyName: (json['company_name'] as String?) ?? '',
      companyPhone: json['company_phone'] as String?,
      guideName: json['guide_name'] as String?,
      guidePhone: json['guide_phone'] as String?,
      chatOpen: json['chat_open'] as bool? ?? false,
      program: program,
      lastAnnouncement: last == null ? null : AnnouncementModel.fromRow(last),
    );
  }
}
