import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/guide_departure.dart';
import '../utils/guide_display.dart';
import 'attendance_counts.dart';
import 'departure_status_banner.dart';

/// Ana ekrandaki kalkış kartı: tur adı, tarih-saat, araç, geldi/gelmedi sayıları.
class GuideDepartureCard extends StatelessWidget {
  const GuideDepartureCard({required this.departure, required this.onTap, super.key});

  final GuideDeparture departure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final vehicle = departure.vehicleLabel;

    return Card(
      margin: AppMargins.cardList,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppPaddings.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(departure.tourTitle, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              _IconText(icon: Icons.event, text: departure.departureLabel),
              if (vehicle != null) _IconText(icon: Icons.directions_bus, text: vehicle),
              const SizedBox(height: AppSpacing.sm),
              AttendanceCounts(
                arrived: departure.checkedInCount,
                notArrived: departure.notArrivedCount,
              ),
              if (departure.statusBanner != null) ...[
                const SizedBox(height: AppSpacing.md),
                DepartureStatusBanner(departure: departure),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
