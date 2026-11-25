import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../constants/strings.dart';

/// İnternet yokken cihazda kayıtlı verinin gösterildiğini belirtir.
class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({this.message = AppStrings.showingCachedTours, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppMargins.cardList,
      padding: AppPaddings.allMd,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: AppSizes.iconMd, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
