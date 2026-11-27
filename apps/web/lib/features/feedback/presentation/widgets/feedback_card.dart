import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/feedback_item.dart';
import '../utils/feedback_display.dart';

/// Geri bildirim kartı. Super admin durumunu açılır listeden değiştirir.
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    required this.item,
    required this.showCompany,
    this.onStatusChanged,
    super.key,
  });

  final FeedbackItem item;
  final bool showCompany;
  final ValueChanged<FeedbackStatus>? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onChanged = onStatusChanged;
    return Card(
      child: Padding(
        padding: AppPaddings.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.title, style: textTheme.titleMedium)),
                if (onChanged == null)
                  ToneBadge(
                    label: item.status.label,
                    tone: switch (item.status) {
                      FeedbackStatus.open => AppTone.warning,
                      FeedbackStatus.inProgress => AppTone.primary,
                      FeedbackStatus.resolved => AppTone.success,
                    },
                  )
                else
                  DropdownButton<FeedbackStatus>(
                    style: PanelTextStyles.body,
                    value: item.status,
                    items: [
                      for (final status in FeedbackStatus.values)
                        DropdownMenuItem(value: status, child: Text(status.label)),
                    ],
                    onChanged: (status) {
                      if (status != null && status != item.status) onChanged(status);
                    },
                  ),
              ],
            ),
            Text(
              [
                if (showCompany) item.companyName,
                item.authorName,
                Formatters.dateTime(item.createdAt),
              ].where((part) => part.isNotEmpty).join(' · '),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(item.body),
          ],
        ),
      ),
    );
  }
}
