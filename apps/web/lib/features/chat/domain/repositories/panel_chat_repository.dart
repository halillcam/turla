import '../entities/panel_chat_message.dart';

/// Firma admininin tur sohbeti denetimi: okur, yazar (tarih açıkken), her mesajı siler.
/// Panelde canlı dinleme yoktur (kota): pencere açılınca ve "Yenile" ile çekilir.
/// Hatalar `PanelFailure` olarak fırlatılır.
abstract interface class PanelChatRepository {
  static const int pageSize = 100;

  /// En yeni mesajlar ([before] verilirse ondan eskiler), yeniden eskiye.
  Future<List<PanelChatMessage>> listMessages(String departureId, {DateTime? before});

  Future<PanelChatMessage> send(String departureId, String body);

  Future<void> delete(String messageId);
}
