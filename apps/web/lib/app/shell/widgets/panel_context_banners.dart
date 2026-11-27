import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../core/constants/strings.dart';
import '../../router/app_routes.dart';
import '../panel_shell.dart';

/// İçeriğin üstündeki bağlam bantları: firma pasifse uyarı; super admin bir firmanın
/// alanındaysa "X firmasını yönetiyorsunuz · Tüm firmalar".
class PanelContextBanners extends StatelessWidget {
  const PanelContextBanners({required this.isSuperAdmin, super.key});

  final bool isSuperAdmin;

  @override
  Widget build(BuildContext context) {
    final company = CompanyScope.of(context);
    if (company == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!company.isActive)
          _Band(
            tone: AppTone.warning,
            child: Text(
              AppStrings.companyInactiveBanner,
              style: PanelTextStyles.bodyStrong.copyWith(color: AppTone.warning.foreground),
            ),
          ),
        if (isSuperAdmin)
          _Band(
            tone: AppTone.primary,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${company.name} ${AppStrings.managingCompanySuffix}',
                    style: PanelTextStyles.bodyStrong.copyWith(color: AppColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.companies),
                  style: TextButton.styleFrom(minimumSize: Size.zero),
                  child: const Text(AppStrings.backToCompanies),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.tone, required this.child});

  final AppTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPaddings.panelBanner,
      decoration: BoxDecoration(
        color: tone.background,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.panelMaxContentWidth),
          child: child,
        ),
      ),
    );
  }
}
