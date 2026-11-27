import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/app_notification.dart';
import '../utils/notification_display.dart';

/// Bildirim satırı: başlık, metin ve saat. Okunmamışsa başlık kalın ve solunda
/// küçük terracotta nokta (vurgu rengi sadece burada, küçük).
class NotificationTile extends StatelessWidget {
  const NotificationTile({required this.notification, required this.onTap, super.key});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppPaddings.listRow,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppPaddings.unreadDot,
              child: Container(
                width: AppSizes.statusDot,
                height: AppSizes.statusDot,
                decoration: BoxDecoration(
                  color: unread ? AppColors.accent : AppColors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: unread ? textTheme.labelLarge : textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    notification.body,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.timeLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
