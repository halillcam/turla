import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// "Geldi 12 · Gelmedi 3 · Toplam 15" sayaçları.
class AttendanceCounts extends StatelessWidget {
  const AttendanceCounts({required this.arrived, required this.notArrived, super.key});

  final int arrived;
  final int notArrived;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _CountChip(label: AppStrings.arrivedCountLabel, value: arrived, color: AppColors.arrived),
        _CountChip(
          label: AppStrings.notArrivedCountLabel,
          value: notArrived,
          color: AppColors.notArrived,
        ),
        _CountChip(
          label: AppStrings.totalCountLabel,
          value: arrived + notArrived,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        '$label $value',
        style: TextStyle(color: color, fontSize: AppFontSizes.caption, fontWeight: FontWeight.w600),
      ),
    );
  }
}
