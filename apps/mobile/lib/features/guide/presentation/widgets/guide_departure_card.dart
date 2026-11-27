import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/guide_departure.dart';
import '../utils/guide_display.dart';
import 'attendance_counts.dart';
import 'departure_status_banner.dart';
import 'plate_chip.dart';

/// Ana ekrandaki kalkış kartı: tur adı ve plaka, tarih-saat, geldi/gelmedi sayıları.
class GuideDepartureCard extends StatelessWidget {
  const GuideDepartureCard({required this.departure, required this.onTap, super.key});

  final GuideDeparture departure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final plate = departure.busPlate;

    return Card(
      margin: AppMargins.cardList,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppPaddings.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(departure.tourTitle, style: textTheme.titleLarge)),
                  if (plate != null && plate.trim().isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    PlateChip(plate: plate),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                departure.departureLabel,
                style: textTheme.bodySmall?.copyWith(fontFeatures: AppTextStyles.tabularFigures),
              ),
              const Padding(padding: AppPaddings.verticalMd, child: Divider()),
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
