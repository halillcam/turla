import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../screens/checkout_screen.dart';
import '../utils/ticket_display.dart';

/// Ödeme özeti: tur, firma, kalkış, yolcu ve toplam tutar.
class CheckoutSummaryCard extends StatelessWidget {
  const CheckoutSummaryCard({required this.args, required this.passengerName, super.key});

  final CheckoutArgs args;
  final String passengerName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: AppPaddings.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(args.tourTitle, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(args.companyName, style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            _SummaryRow(label: AppStrings.departureRowLabel, value: args.departureLabel),
            if (passengerName.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _SummaryRow(label: AppStrings.passengerRowLabel, value: passengerName),
            ],
            const Padding(padding: AppPaddings.verticalLg, child: Divider()),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(AppStrings.totalAmount, style: textTheme.labelLarge)),
                Text(
                  args.priceLabel,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.labelMedium?.copyWith(fontFeatures: AppTextStyles.tabularFigures),
          ),
        ),
      ],
    );
  }
}
