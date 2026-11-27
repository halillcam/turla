import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// "Geldi 12" / "Gelmedi 3" rozetleri ve sağda "15 katılımcı".
class AttendanceCounts extends StatelessWidget {
  const AttendanceCounts({required this.arrived, required this.notArrived, super.key});

  final int arrived;
  final int notArrived;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              ToneBadge(label: '${AppStrings.arrivedCountLabel} $arrived', tone: AppTone.success),
              ToneBadge(
                label: '${AppStrings.notArrivedCountLabel} $notArrived',
                tone: AppTone.error,
              ),
            ],
          ),
        ),
        Text(
          '${arrived + notArrived} ${AppStrings.participantCountSuffix}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontFeatures: AppTextStyles.tabularFigures),
        ),
      ],
    );
  }
}
