import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Profilde ikon + etiket + değer satırı, isteğe bağlı eylem düğmesiyle.
class ProfileInfoTile extends StatelessWidget {
  const ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final action = actionLabel;
    return Padding(
      padding: AppPaddings.listRow,
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconMd, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                Text(value, style: textTheme.bodyMedium),
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(textStyle: AppTextStyles.labelMedium),
              child: Text(action),
            ),
        ],
      ),
    );
  }
}
