import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Ekranın altında kısa mesaj. Hata mesajı kırmızı zeminde ikonla gösterilir.
abstract final class AppSnackBar {
  static void show(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? AppColors.error : null,
          content: Row(
            children: [
              if (isError) ...[
                const Icon(
                  Icons.error_outline,
                  size: AppSizes.iconBanner,
                  color: AppColors.onPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
