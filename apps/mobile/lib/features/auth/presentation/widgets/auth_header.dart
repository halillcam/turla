import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(CoreStrings.appName, style: textTheme.titleLarge?.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: textTheme.displaySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
