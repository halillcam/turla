import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// Geçici açılış ekranı. Faz 1'de şehir seçimi ve tur listesi ile değiştirilecek.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppPaddings.screen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(CoreStrings.appName, style: textTheme.displaySmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.homeTagline,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  AppStrings.homeSetupNotice,
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
