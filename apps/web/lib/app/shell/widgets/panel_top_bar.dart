import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../core/constants/strings.dart';
import '../panel_shell.dart';

/// Üst çubuk: (varsa) firma adı ve pasif uyarısı, kullanıcı, çıkış.
class PanelTopBar extends StatelessWidget {
  const PanelTopBar({
    required this.userName,
    required this.roleLabel,
    required this.onSignOut,
    super.key,
  });

  final String userName;
  final String roleLabel;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final company = CompanyScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: AppPaddings.screen,
          child: Row(
            children: [
              Expanded(child: Text(company?.name ?? '', style: textTheme.titleMedium)),
              Text('$userName · $roleLabel', style: textTheme.bodyMedium),
              const SizedBox(width: AppSpacing.md),
              TextButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.signOut),
              ),
            ],
          ),
        ),
        if (company != null && !company.isActive)
          Container(
            width: double.infinity,
            color: AppColors.warning,
            padding: AppPaddings.allSm,
            child: Text(
              AppStrings.companyInactiveBanner,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary),
            ),
          ),
      ],
    );
  }
}
