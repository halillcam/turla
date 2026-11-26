import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// İkon + etiket + değer satırı (bilet ve satın alma özetleri).
class InfoRow extends StatelessWidget {
  const InfoRow({required this.icon, required this.label, required this.value, super.key});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: AppPaddings.verticalSm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconMd, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                Text(value, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
