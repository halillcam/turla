import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/app_notification.dart';
import '../utils/notification_display.dart';

/// Bildirim satırı: okunmamışsa kalın ve noktalı.
class NotificationTile extends StatelessWidget {
  const NotificationTile({required this.notification, required this.onTap, super.key});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unread = !notification.isRead;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        unread ? Icons.campaign : Icons.campaign_outlined,
        color: unread ? AppColors.primary : AppColors.textMuted,
      ),
      title: Text(
        notification.title,
        style: textTheme.bodyLarge?.copyWith(fontWeight: unread ? FontWeight.w700 : null),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body),
          const SizedBox(height: AppSpacing.xxs),
          Text(notification.timeLabel, style: textTheme.labelSmall),
        ],
      ),
      isThreeLine: true,
    );
  }
}
