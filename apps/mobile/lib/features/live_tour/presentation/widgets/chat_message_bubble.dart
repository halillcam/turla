import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/chat_message.dart';
import '../utils/live_tour_display.dart';

/// Sohbet mesajı balonu. Kendi mesajın sağda, diğerleri solda; rehber/firma
/// mesajları vurgulu renkte ve etiketli.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    required this.currentUserId,
    required this.now,
    this.onLongPress,
    super.key,
  });

  final ChatMessage message;
  final String? currentUserId;
  final DateTime now;

  /// Kendi mesajında silme (null ise basılı tutma kapalı).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mine = message.isMine(currentUserId);
    final background = mine
        ? AppColors.primaryLight
        : (message.isStaff ? AppColors.surfaceMuted : AppColors.surface);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSizes.chatBubbleMaxWidth),
          margin: AppPaddings.verticalXs,
          padding: AppPaddings.allMd,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: message.isStaff ? AppColors.primary : AppColors.border,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.senderLabel(currentUserId),
                style: textTheme.labelMedium?.copyWith(
                  color: message.isStaff ? AppColors.primaryDark : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(message.body, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(message.timeLabel(now), style: textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
