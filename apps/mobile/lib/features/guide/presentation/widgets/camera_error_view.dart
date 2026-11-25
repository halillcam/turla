import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// Kamera izni verilmedi / kamera açılamadı: açıklama ve "Kodu elle gir".
class CameraErrorView extends StatelessWidget {
  const CameraErrorView({required this.permissionDenied, required this.onEnterCode, super.key});

  final bool permissionDenied;
  final VoidCallback onEnterCode;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Padding(
          padding: AppPaddings.allXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                permissionDenied ? Icons.no_photography_outlined : Icons.videocam_off_outlined,
                size: AppSizes.iconXl,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                permissionDenied ? AppStrings.cameraPermissionDenied : AppStrings.cameraUnavailable,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onEnterCode,
                icon: const Icon(Icons.keyboard),
                label: const Text(AppStrings.enterCodeManually),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
