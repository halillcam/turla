import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/announcement.dart';
import '../utils/live_tour_display.dart';

/// Duyuru kartı: saat ve metin.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({required this.announcement, this.title, super.key});

  final Announcement announcement;

  /// Verilirse kartın üstünde başlık (ör. "Son duyuru").
  final String? title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: AppPaddings.verticalXs,
      child: Padding(
        padding: AppPaddings.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_outlined, size: AppSizes.iconMd, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title ?? announcement.timeLabel, style: textTheme.labelLarge)),
                if (title != null) Text(announcement.timeLabel, style: textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(announcement.body, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
