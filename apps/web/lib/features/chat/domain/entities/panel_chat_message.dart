import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

/// Panelde görülen tur sohbeti mesajı.
class PanelChatMessage extends Equatable {
  const PanelChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  /// Sunucudaki sınır (messages.body check).
  static const int maxLength = 2000;

  final String id;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String body;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, senderId, senderName, senderRole, body, createdAt];
}
