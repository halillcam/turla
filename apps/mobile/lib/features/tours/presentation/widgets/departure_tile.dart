import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/tour_departure.dart';
import 'seats_badge.dart';

/// Kalkış tarihi seçim kartı: tarih · saat ve boş koltuk. Dokununca seçilir; dolu tarih
/// soluk görünür ve seçilemez.
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
    final background = isSelected
        ? AppColors.primaryTint
        : isEnabled
        ? AppColors.surface
        : AppColors.surfaceMuted;
    final dateStyle = isSelected
        ? textTheme.labelLarge?.copyWith(color: AppColors.primary)
        : textTheme.bodyMedium?.copyWith(
            color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
          );

    return Padding(
      padding: AppMargins.listItem,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: AppSizes.borderWidth,
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.lgAll,
          onTap: isEnabled ? onSelected : null,
          child: Padding(
            padding: AppPaddings.tourCard,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: AppSizes.navigationIcon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Formatters.date(departure.departureAt)} · '
                        '${Formatters.time(departure.departureAt)}',
                        style: dateStyle?.copyWith(fontFeatures: AppTextStyles.tabularFigures),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SeatsBadge(seatsLeft: departure.seatsLeft),
                    ],
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
