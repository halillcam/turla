import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/guide_departure.dart';
import '../utils/guide_display.dart';
import 'attendance_counts.dart';
import 'departure_status_banner.dart';

/// Katılımcı ekranının üstü: tarih-saat, araç/şoför (şoförü arama), sayılar ve durum bandı.
class DepartureHeader extends StatelessWidget {
  const DepartureHeader({
    required this.departure,
    required this.arrived,
    required this.notArrived,
    required this.onCallDriver,
    super.key,
  });

  final GuideDeparture departure;
  final int arrived;
  final int notArrived;
  final VoidCallback onCallDriver;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final vehicle = departure.vehicleLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DepartureStatusBanner(departure: departure),
        Text(departure.departureLabel, style: textTheme.titleSmall),
        if (vehicle != null)
          Row(
            children: [
              Expanded(child: Text(vehicle, style: textTheme.bodyMedium)),
              if (departure.hasDriverPhone)
                IconButton(
                  tooltip: AppStrings.callDriver,
                  onPressed: onCallDriver,
                  icon: const Icon(Icons.phone, size: AppSizes.iconMd),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
        AttendanceCounts(arrived: arrived, notArrived: notArrived),
      ],
    );
  }
}
