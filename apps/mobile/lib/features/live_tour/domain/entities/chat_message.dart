import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

/// Tur sohbetindeki bir mesaj. Gönderen adı ve rolü sunucuda profilden yazılır.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.departureId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  /// Sunucudaki sınır (messages.body check).
  static const int maxLength = 2000;

  final String id;
  final String departureId;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String body;
  final DateTime createdAt;

  bool isMine(String? userId) => userId != null && senderId == userId;

  /// Tur sorumlusu veya firma mesajı (ekranda etiketle ayrılır).
  bool get isStaff => senderRole != UserRole.customer;

  @override
  List<Object?> get props => [id, departureId, senderId, senderName, senderRole, body, createdAt];
}
