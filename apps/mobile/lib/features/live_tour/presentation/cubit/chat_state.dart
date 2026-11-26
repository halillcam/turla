part of 'chat_cubit.dart';

enum ChatStatus { loading, ready, failure }

final class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.loading,
    this.messages = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.canWrite = false,
    this.currentUserId,
    this.sentCount = 0,
    this.failure,
    this.actionFailure,
  });

  final ChatStatus status;

  /// Yeniden eskiye (liste ters çizilir: en yeni altta).
  final List<ChatMessage> messages;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isSending;

  /// Yazma açık mı (tarih planlanmış). Kapalıysa sohbet salt okunur görünür.
  final bool canWrite;
  final String? currentUserId;

  /// Her başarılı gönderimde artar; ekran yazı kutusunu temizler.
  final int sentCount;

  /// İlk yükleme hatası.
  final LiveTourFailureReason? failure;

  /// Gönderme/silme/eski sayfa hatası (ekranda kısa mesaj).
  final LiveTourFailureReason? actionFailure;

  bool canDelete(ChatMessage message) => message.isMine(currentUserId);

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isSending,
    bool? canWrite,
    int? sentCount,
    LiveTourFailureReason? failure,
    LiveTourFailureReason? actionFailure,
    bool clearActionFailure = false,
  }) => ChatState(
    status: status ?? this.status,
    messages: messages ?? this.messages,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isSending: isSending ?? this.isSending,
    canWrite: canWrite ?? this.canWrite,
    currentUserId: currentUserId,
    sentCount: sentCount ?? this.sentCount,
    failure: failure ?? this.failure,
    actionFailure: clearActionFailure ? null : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => [
    status,
    messages,
    hasMore,
    isLoadingMore,
    isSending,
    canWrite,
    currentUserId,
    sentCount,
    failure,
    actionFailure,
  ];
}
