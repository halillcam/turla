import '../entities/chat_message.dart';

/// Tur sohbeti. Mesajlar sayfa sayfa çekilir; yeni mesajlar sadece sohbet ekranı
/// açıkken canlı dinlenir ([watch] aboneliği iptal edilince kanal kapanır).
/// Hatalar [LiveTourFailure] olarak fırlatılır.
abstract interface class ChatRepository {
  /// Bir sayfadaki mesaj sayısı.
  static const int pageSize = 50;

  /// Oturumdaki kullanıcı (kendi mesajını ayırmak için).
  String? get currentUserId;

  /// En yeni mesajlar ([before] verilirse ondan eskiler), yeniden eskiye.
  Future<List<ChatMessage>> fetchPage(String departureId, {DateTime? before});

  Future<ChatMessage> send(String departureId, String body);

  Future<void> delete(String messageId);

  /// Bu tarihe gelen yeni mesajlar (Realtime). Dinleme bitince kanal kapanır.
  Stream<ChatMessage> watch(String departureId);
}
