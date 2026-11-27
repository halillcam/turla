import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// Bilet kartının QR bölümü: beyaz kutuda QR, altında mono kod ve kısa ipucu.
/// Değer cihazdaki kayıttan gelir; internet gerekmez.
class TicketQrSection extends StatelessWidget {
  const TicketQrSection({required this.qrToken, super.key});

  final String qrToken;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPaddings.ticketSection,
      child: Column(
        children: [
          Container(
            padding: AppPaddings.allLg,
            decoration: BoxDecoration(
              color: AppColors.onPrimary,
              borderRadius: AppRadius.mdPlusAll,
              border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
            ),
            child: QrImageView(
              data: qrToken,
              size: AppSizes.qrCode,
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.onPrimary,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textPrimary),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.textPrimary,
              ),
              semanticsLabel: AppStrings.showQrToGuide,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectableText(qrToken, style: AppTextStyles.mono, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.showQrToGuide,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
