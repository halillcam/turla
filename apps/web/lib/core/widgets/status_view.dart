import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../constants/strings.dart';

/// Yükleniyor / hata / boş durumları için ortak görünüm.
class StatusView extends StatelessWidget {
  const StatusView.loading({super.key})
    : message = null,
      icon = null,
      onAction = null,
      actionLabel = AppStrings.retry;

  const StatusView.message({
    required String this.message,
    super.key,
    this.icon = Icons.info_outline,
    this.onAction,
    this.actionLabel = AppStrings.retry,
  });

  final String? message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: AppPaddings.allXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconXl, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
