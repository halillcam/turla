import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// Biletin QR kodu. Değer cihazdaki kayıttan gelir; internet gerekmez.
class TicketQrCard extends StatelessWidget {
  const TicketQrCard({required this.qrToken, super.key});

  final String qrToken;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPaddings.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrToken,
            size: AppSizes.qrCode,
            backgroundColor: AppColors.surface,
            semanticsLabel: AppStrings.showQrToGuide,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.showQrToGuide,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
