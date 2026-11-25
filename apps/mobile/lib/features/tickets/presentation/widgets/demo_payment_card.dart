import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// MVP'deki demo ödeme kutusu: kart alanı yok, gerçek tahsilat yapılmaz.
class DemoPaymentCard extends StatelessWidget {
  const DemoPaymentCard({required this.priceLabel, super.key});

  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: AppPaddings.card,
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, size: AppSizes.iconMd, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(AppStrings.demoPaymentTitle, style: textTheme.titleSmall)),
              Text(
                '${AppStrings.totalAmount}: $priceLabel',
                style: textTheme.titleSmall?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.demoPaymentNote, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
