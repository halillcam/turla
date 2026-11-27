import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../auth/presentation/utils/auth_navigation.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';

/// Misafir profili: giriş / kayıt daveti kartı.
class GuestProfileView extends StatelessWidget {
  const GuestProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: AppPaddings.allXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.person_outline,
              size: AppSizes.iconPlaceholder,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.guestProfileTitle,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.guestProfileMessage,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => AuthNavigation.openLogin(context),
              child: const Text(AppStrings.loginButton),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.register),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: AppSizes.borderWidth),
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              ),
              child: const Text(AppStrings.goToRegister),
            ),
          ],
        ),
      ),
    );
  }
}
