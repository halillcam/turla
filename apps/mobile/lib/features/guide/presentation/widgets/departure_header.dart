import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/guide_departure.dart';
import '../utils/guide_display.dart';
import 'departure_status_banner.dart';
import 'plate_chip.dart';

/// Katılımcı ekranının üstü: durum bandı, tarih-saat, plaka + şoför (arama).
/// Geldi/Gelmedi sayıları altındaki süzgeç haplarında görünür.
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
    final plate = departure.busPlate;
    final driverLine = departure.driverLine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DepartureStatusBanner(departure: departure),
        Card(
          child: Padding(
            padding: AppPaddings.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  departure.departureLabel,
                  style: textTheme.labelLarge?.copyWith(fontFeatures: AppTextStyles.tabularFigures),
                ),
                if (plate != null || driverLine != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (plate != null && plate.trim().isNotEmpty) ...[
                        PlateChip(plate: plate),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(child: Text(driverLine ?? '', style: textTheme.bodySmall)),
                      if (departure.hasDriverPhone)
                        IconButton(
                          tooltip: AppStrings.callDriver,
                          onPressed: onCallDriver,
                          color: AppColors.primary,
                          icon: const Icon(Icons.call_outlined, size: AppSizes.iconMd),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
