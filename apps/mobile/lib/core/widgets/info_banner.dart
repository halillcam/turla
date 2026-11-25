import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Renkli bilgi bandı (onay bekliyor, reddedildi, tamamlandı ...).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.message,
    this.icon = Icons.info_outline,
    this.color = AppColors.info,
    super.key,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppMargins.cardList,
      padding: AppPaddings.allMd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconMd, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
