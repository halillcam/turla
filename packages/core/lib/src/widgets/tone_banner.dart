import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/paddings.dart';
import '../constants/radius.dart';
import '../constants/sizes.dart';
import '../theme/app_text_styles.dart';
import 'app_tone.dart';

/// Tonlu bilgi bandı (internet yok, onay bekliyor, QR okutuldu ...).
class ToneBanner extends StatelessWidget {
  const ToneBanner({
    required this.message,
    this.tone = AppTone.primary,
    this.icon = Icons.info_outline,
    this.title,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final String message;
  final AppTone tone;
  final IconData icon;
  final String? title;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final titleText = title;
    return Container(
      margin: margin,
      padding: AppPaddings.banner,
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconBanner, color: tone.foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titleText != null)
                  Text(titleText, style: AppTextStyles.labelLarge.copyWith(color: tone.foreground)),
                Text(message, style: AppTextStyles.bodySmall.copyWith(color: tone.foreground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
