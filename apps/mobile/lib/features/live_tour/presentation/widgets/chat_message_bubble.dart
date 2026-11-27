import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/chat_message.dart';
import '../utils/live_tour_display.dart';

/// Sohbet mesajı: balonun üstünde gönderen adı (rehber/firma etiketi ana renkte),
/// balonun içinde metin ve sağ altta saat. Kendi mesajın sağda ve açık yeşil zeminde.
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
    final foreground = mine ? AppColors.primary : AppColors.textPrimary;
    final tag = message.roleTag;
    final name = message.senderDisplayName(currentUserId);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.chatBubbleMaxWidth),
        child: Padding(
          padding: AppPaddings.chatMessage,
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: AppPaddings.horizontalXs,
                child: Text.rich(
                  TextSpan(
                    text: name,
                    children: [
                      if (tag != null) ...[
                        const TextSpan(text: AppStrings.nameSeparator),
                        TextSpan(
                          text: tag,
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                  style: textTheme.labelSmall?.copyWith(
                    color: mine ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  padding: AppPaddings.chatBubble,
                  decoration: BoxDecoration(
                    color: mine ? AppColors.primaryTint : AppColors.surface,
                    borderRadius: AppRadius.lgAll,
                    border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        child: Text(
                          message.body,
                          style: textTheme.bodyMedium?.copyWith(color: foreground),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        message.timeLabel(now),
                        style: textTheme.labelSmall?.copyWith(
                          color: mine ? AppColors.primary : AppColors.textSecondary,
                          fontFeatures: AppTextStyles.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
