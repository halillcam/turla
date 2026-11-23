import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Oturum ve seçili il yüklenirken kısa süre görünür.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CoreStrings.appName,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
