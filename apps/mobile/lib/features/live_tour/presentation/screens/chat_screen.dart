import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/status_view.dart';
import '../../domain/entities/chat_message.dart';
import '../cubit/chat_cubit.dart';
import '../utils/live_tour_display.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/message_composer.dart';

/// Sohbet ekranını açan taraf yazma iznini bilir (tarih planlanmış mı).
class ChatScreenArgs {
  const ChatScreenArgs({required this.canWrite});

  final bool canWrite;
}

/// Tur sohbeti (müşteri ve tur sorumlusu). Realtime aboneliği sadece bu ekran
/// açıkken yaşar.
class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.departureId, this.args, super.key});

  final String departureId;
  final ChatScreenArgs? args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ChatCubit>()..start(departureId, canWrite: args?.canWrite ?? false),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView();

  Future<void> _confirmDelete(BuildContext context, ChatMessage message) async {
    final cubit = context.read<ChatCubit>();
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.chatDeleteTitle,
      message: AppStrings.chatDeleteMessage,
      confirmLabel: AppStrings.chatDeleteConfirm,
    );
    if (confirmed) await cubit.delete(message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          current.actionFailure != null && previous.actionFailure != current.actionFailure,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.actionFailure!.message)));
        context.read<ChatCubit>().clearActionFailure();
      },
      builder: (context, state) {
        final cubit = context.read<ChatCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.tourChat)),
          body: Column(
            children: [
              if (!state.canWrite)
                const Padding(
                  padding: AppPaddings.allSm,
                  child: InfoBanner(
                    message: AppStrings.chatReadOnly,
                    icon: Icons.lock_outline,
                    color: AppColors.info,
                  ),
                ),
              Expanded(child: _messages(context, state, cubit)),
              if (state.canWrite)
                MessageComposer(
                  hint: AppStrings.chatInputHint,
                  sendLabel: AppStrings.chatSend,
                  maxLength: ChatMessage.maxLength,
                  isSending: state.isSending,
                  onSend: cubit.send,
                  resetToken: state.sentCount,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _messages(BuildContext context, ChatState state, ChatCubit cubit) {
    if (state.status == ChatStatus.loading && state.messages.isEmpty) {
      return const StatusView.loading();
    }
    if (state.status == ChatStatus.failure && state.messages.isEmpty) {
      return StatusView.message(
        message: state.failure?.message ?? AppStrings.chatLoadError,
        icon: Icons.wifi_off,
        onAction: cubit.retry,
      );
    }
    if (state.messages.isEmpty) {
      return const StatusView.message(message: AppStrings.chatEmpty, icon: Icons.forum_outlined);
    }
    final now = DateTime.now();
    final messages = state.messages;
    // Ters liste: en yeni altta; sona gelince (en eski) önceki sayfa yüklenir.
    return ListView.builder(
      reverse: true,
      padding: AppPaddings.screen,
      itemCount: messages.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Center(
            child: state.isLoadingMore
                ? const Padding(padding: AppPaddings.allSm, child: CircularProgressIndicator())
                : TextButton(onPressed: cubit.loadMore, child: const Text(AppStrings.chatLoadOlder)),
          );
        }
        final message = messages[index];
        return ChatMessageBubble(
          message: message,
          currentUserId: state.currentUserId,
          now: now,
          onLongPress: state.canDelete(message) && state.canWrite
              ? () => _confirmDelete(context, message)
              : null,
        );
      },
    );
  }
}
