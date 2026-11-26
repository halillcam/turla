import 'package:equatable/equatable.dart';

/// Tur sorumlusunun (veya firmanın) o tarihin QR'ı okutulmuş yolcularına duyurusu.
class Announcement extends Equatable {
  const Announcement({required this.id, required this.body, required this.createdAt});

  /// Sunucudaki sınır (announcements.body check).
  static const int maxLength = 1000;

  final String id;
  final String body;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, body, createdAt];
}
