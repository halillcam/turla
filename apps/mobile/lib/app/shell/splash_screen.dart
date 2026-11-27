import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../core/constants/strings.dart';

/// Oturum ve seçili il yüklenirken kısa süre görünür.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.splash,
          child: Column(
            children: [
              const Spacer(),
              Text(
                CoreStrings.appName,
                style: textTheme.displayLarge?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.appTagline,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              const SizedBox(
                width: AppSizes.splashProgressWidth,
                child: ClipRRect(
                  borderRadius: AppRadius.pillAll,
                  child: LinearProgressIndicator(minHeight: AppSizes.splashProgressHeight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
