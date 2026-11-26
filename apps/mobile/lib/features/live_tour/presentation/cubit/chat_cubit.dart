import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/live_tour_failure.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_state.dart';

/// Tur sohbeti. Ekran açılınca son sayfa çekilir ve Realtime aboneliği başlar;
/// ekran kapanınca (cubit kapanınca) abonelik iptal edilir, kanal kapanır.
/// Yukarı kaydırınca eski mesajlar sayfa sayfa gelir.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository) : super(const ChatState());

  final ChatRepository _repository;
  StreamSubscription<ChatMessage>? _subscription;
  String? _departureId;

  Future<void> start(String departureId, {required bool canWrite}) async {
    _departureId = departureId;
    emit(ChatState(currentUserId: _repository.currentUserId, canWrite: canWrite));
    // Önce dinlemeye başla: ilk sayfa gelene kadar yazılan mesaj kaçmasın.
    await _subscription?.cancel();
    _subscription = _repository.watch(departureId).listen(_onIncoming, onError: (_) {});
    await _loadFirstPage();
  }

  Future<void> retry() => _loadFirstPage();

  Future<void> _loadFirstPage() async {
    final departureId = _departureId;
    if (departureId == null) return;
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final page = await _repository.fetchPage(departureId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ChatStatus.ready,
          messages: _merge(state.messages, page),
          hasMore: page.length >= ChatRepository.pageSize,
        ),
      );
    } on LiveTourFailure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(status: ChatStatus.failure, failure: failure.reason));
    }
  }

  Future<void> loadMore() async {
    final departureId = _departureId;
    if (departureId == null || !state.hasMore || state.isLoadingMore || state.messages.isEmpty) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.fetchPage(departureId, before: state.messages.last.createdAt);
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          messages: _merge(state.messages, page),
          hasMore: page.length >= ChatRepository.pageSize,
        ),
      );
    } on LiveTourFailure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(isLoadingMore: false, actionFailure: failure.reason));
    }
  }

  Future<void> send(String body) async {
    final departureId = _departureId;
    final text = body.trim();
    if (departureId == null || text.isEmpty || state.isSending || !state.canWrite) return;
    emit(state.copyWith(isSending: true));
    try {
      final message = await _repository.send(departureId, text);
      if (isClosed) return;
      emit(
        state.copyWith(
          isSending: false,
          messages: _merge(state.messages, [message]),
          sentCount: state.sentCount + 1,
        ),
      );
    } on LiveTourFailure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSending: false,
          actionFailure: failure.reason,
          // Sunucu yazmayı reddettiyse (tur bitti) kutu kapanır.
          canWrite: failure.reason != LiveTourFailureReason.notAllowed && state.canWrite,
        ),
      );
    }
  }

  Future<void> delete(ChatMessage message) async {
    try {
      await _repository.delete(message.id);
      if (isClosed) return;
      emit(
        state.copyWith(messages: state.messages.where((other) => other.id != message.id).toList()),
      );
    } on LiveTourFailure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(actionFailure: failure.reason));
    }
  }

  void clearActionFailure() => emit(state.copyWith(clearActionFailure: true));

  void _onIncoming(ChatMessage message) {
    if (isClosed) return;
    emit(state.copyWith(messages: _merge(state.messages, [message])));
  }

  /// Kimliğe göre tekrarları atar, yeniden eskiye sıralar.
  static List<ChatMessage> _merge(List<ChatMessage> current, List<ChatMessage> incoming) {
    final byId = {for (final message in current) message.id: message};
    for (final message in incoming) {
      byId[message.id] = message;
    }
    return byId.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
