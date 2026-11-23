import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// "5 koltuk kaldı" / "Dolu" rozeti.
class SeatsBadge extends StatelessWidget {
  const SeatsBadge({required this.seatsLeft, super.key});

  final int seatsLeft;

  @override
  Widget build(BuildContext context) {
    final isSoldOut = seatsLeft <= 0;
    final color = isSoldOut ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        isSoldOut ? AppStrings.soldOut : '$seatsLeft ${AppStrings.seatsLeftSuffix}',
        style: TextStyle(color: color, fontSize: AppFontSizes.caption, fontWeight: FontWeight.w600),
      ),
    );
  }
}
