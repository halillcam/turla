import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Plaka etiketi: soluk zeminde eş aralıklı yazı ("46 ABC 101").
class PlateChip extends StatelessWidget {
  const PlateChip({required this.plate, super.key});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surfaceMuted, borderRadius: AppRadius.smAll),
      child: Padding(
        padding: AppPaddings.plateChip,
        child: Text(plate, style: AppTextStyles.mono),
      ),
    );
  }
}
