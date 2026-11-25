import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/tour_departure.dart';
import 'seats_badge.dart';

/// Kalkış tarihi satırı: tarih, saat ve boş koltuk. Dokununca seçilir (dolu tarih seçilemez).
class DepartureTile extends StatelessWidget {
  const DepartureTile({
    required this.departure,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final TourDeparture departure;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = !departure.isSoldOut;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: isSelected ? AppColors.primaryLight : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: AppSizes.borderWidth,
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: isEnabled ? onSelected : null,
          child: Padding(
            padding: AppPaddings.allMd,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: AppSizes.iconMd,
                  color: isEnabled ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Formatters.date(departure.departureAt), style: textTheme.bodyLarge),
                      Text(Formatters.time(departure.departureAt), style: textTheme.bodySmall),
                    ],
                  ),
                ),
                SeatsBadge(seatsLeft: departure.seatsLeft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
