import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/announcement.dart';
import '../utils/live_tour_display.dart';

/// Duyuru kartı: solda ince terracotta şerit, üstte "Son duyuru · saat", altta metin.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({required this.announcement, this.title, super.key});

  final Announcement announcement;

  /// Verilirse saatin önüne yazılır (ör. "Son duyuru").
  final String? title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final heading = title == null ? announcement.timeLabel : '$title · ${announcement.timeLabel}';
    return Padding(
      padding: AppMargins.listItem,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ColoredBox(
                  color: AppColors.accent,
                  child: SizedBox(width: AppSizes.accentStripe),
                ),
                Expanded(
                  child: Padding(
                    padding: AppPaddings.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heading,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.onWarningTint,
                            fontFeatures: AppTextStyles.tabularFigures,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(announcement.body, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
