import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/tour_departure.dart';
import 'seats_badge.dart';

/// Kalkış tarihi satırı: tarih, saat ve boş koltuk.
class DepartureTile extends StatelessWidget {
  const DepartureTile({required this.departure, super.key});

  final TourDeparture departure;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppPaddings.allMd,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, size: AppSizes.iconMd, color: AppColors.primary),
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
    );
  }
}
