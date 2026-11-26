import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../domain/entities/panel_chat_message.dart';
import '../../domain/repositories/panel_chat_repository.dart';

/// Bir tarihin sohbet denetimi (panel). Gönderilen/silinen mesaj yerelde
/// güncellenir; liste yeniden çekilmez.
class PanelChatCubit extends Cubit<PanelChatState> {
  PanelChatCubit({required this.departureId, required this.canWrite, required this._repository})
    : super(const PanelChatState());

  final String departureId;

  /// Tarih planlanmışsa yazılabilir (sunucu kuralı); bitmiş turda salt okunur.
  final bool canWrite;
  final PanelChatRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final page = await _repository.listMessages(departureId);
      emit(
        PanelChatState(
          status: LoadStatus.ready,
          messages: page,
          hasMore: page.length >= PanelChatRepository.pageSize,
        ),
      );
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    }
  }

  Future<ActionResult<void>> loadMore() async {
    if (!state.hasMore || state.messages.isEmpty) return const ActionResult.success();
    final result = await runAction(
      () => _repository.listMessages(departureId, before: state.messages.last.createdAt),
    );
    final page = result.value;
    if (page != null) {
      emit(
        state.copyWith(
          messages: [...state.messages, ...page],
          hasMore: page.length >= PanelChatRepository.pageSize,
        ),
      );
    }
    return result;
  }

  Future<ActionResult<PanelChatMessage>> send(String body) async {
    if (!canWrite || body.trim().isEmpty) return const ActionResult.success();
    emit(state.copyWith(isBusy: true));
    final result = await runAction(() => _repository.send(departureId, body));
    final message = result.value;
    emit(
      state.copyWith(
        isBusy: false,
        messages: message == null ? null : [message, ...state.messages],
      ),
    );
    return result;
  }

  Future<ActionResult<void>> delete(PanelChatMessage message) async {
    emit(state.copyWith(isBusy: true));
    final result = await runAction(() => _repository.delete(message.id));
    emit(
      state.copyWith(
        isBusy: false,
        messages: result.isSuccess
            ? state.messages.where((other) => other.id != message.id).toList()
            : null,
      ),
    );
    return result;
  }
}

final class PanelChatState extends Equatable {
  const PanelChatState({
    this.status = LoadStatus.initial,
    this.messages = const [],
    this.hasMore = false,
    this.isBusy = false,
    this.loadFailure,
  });

  final LoadStatus status;

  /// Yeniden eskiye.
  final List<PanelChatMessage> messages;
  final bool hasMore;
  final bool isBusy;
  final PanelFailureReason? loadFailure;

  PanelChatState copyWith({
    LoadStatus? status,
    List<PanelChatMessage>? messages,
    bool? hasMore,
    bool? isBusy,
    PanelFailureReason? loadFailure,
  }) => PanelChatState(
    status: status ?? this.status,
    messages: messages ?? this.messages,
    hasMore: hasMore ?? this.hasMore,
    isBusy: isBusy ?? this.isBusy,
    loadFailure: loadFailure ?? this.loadFailure,
  );

  @override
  List<Object?> get props => [status, messages, hasMore, isBusy, loadFailure];
}
