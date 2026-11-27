import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../core/constants/strings.dart';
import '../../router/app_routes.dart';
import '../panel_shell.dart';

/// Sol menü (soluk zemin): üstte "Turla Panel", super admin için platform menüsü,
/// firma alanındaysa firma adı + firma menüsü, en altta kullanıcı ve çıkış.
class PanelSidebar extends StatelessWidget {
  const PanelSidebar({
    required this.location,
    required this.companyId,
    required this.showCompanies,
    required this.userName,
    required this.roleLabel,
    required this.onSignOut,
    super.key,
  });

  final String location;
  final String? companyId;
  final bool showCompanies;
  final String userName;
  final String roleLabel;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final id = companyId;
    final company = CompanyScope.of(context);
    return Container(
      width: AppSizes.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(
          right: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
      ),
      padding: AppPaddings.panelSidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: AppPaddings.horizontalSm,
                  child: Text(AppStrings.panelTitle, style: PanelTextStyles.wordmark),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (showCompanies)
                  _NavItem(
                    icon: Icons.domain,
                    label: AppStrings.navCompanies,
                    target: AppRoutes.companies,
                    selected: location.startsWith(AppRoutes.companies),
                  ),
                if (showCompanies && id == null) ...[
                  _NavItem(
                    icon: Icons.campaign_outlined,
                    label: AppStrings.navAnnouncements,
                    target: AppRoutes.announcements,
                    selected: location.startsWith(AppRoutes.announcements),
                  ),
                  _NavItem(
                    icon: Icons.feedback_outlined,
                    label: AppStrings.navFeedback,
                    target: AppRoutes.feedback,
                    selected: location.startsWith(AppRoutes.feedback),
                  ),
                ],
                if (id != null) ...[
                  if (showCompanies) ...[
                    const Padding(padding: AppPaddings.verticalLg, child: Divider()),
                    if (company != null) _CompanyBox(name: company.name),
                  ] else if (company != null)
                    _CompanyBox(name: company.name),
                  _NavItem(
                    icon: Icons.map_outlined,
                    label: AppStrings.navTours,
                    target: AppRoutes.tours(id),
                    selected: location.startsWith(AppRoutes.tours(id)),
                  ),
                  _NavItem(
                    icon: Icons.badge_outlined,
                    label: AppStrings.navStaff,
                    target: AppRoutes.staff(id),
                    selected: location.startsWith(AppRoutes.staff(id)),
                  ),
                  _NavItem(
                    icon: Icons.task_alt,
                    label: AppStrings.navCompletions,
                    target: AppRoutes.completions(id),
                    selected: location.startsWith(AppRoutes.completions(id)),
                  ),
                  _NavItem(
                    icon: Icons.campaign_outlined,
                    label: AppStrings.navAnnouncements,
                    target: AppRoutes.companyAnnouncements(id),
                    selected: location.startsWith(AppRoutes.companyAnnouncements(id)),
                  ),
                  _NavItem(
                    icon: Icons.feedback_outlined,
                    label: AppStrings.navFeedback,
                    target: AppRoutes.companyFeedback(id),
                    selected: location.startsWith(AppRoutes.companyFeedback(id)),
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: AppPaddings.horizontalXs,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: PanelTextStyles.bodyStrong),
                Text(
                  roleLabel,
                  style: PanelTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onSignOut,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(0, AppSizes.panelSignOutHeight),
                padding: AppPaddings.horizontalXs,
                textStyle: PanelTextStyles.labelMedium,
              ),
              icon: const Icon(Icons.logout, size: AppSizes.iconBanner),
              label: const Text(AppStrings.signOut),
            ),
          ),
        ],
      ),
    );
  }
}

/// Firma alanında menünün üstündeki firma adı kutusu.
class _CompanyBox extends StatelessWidget {
  const _CompanyBox({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppMargins.cardList,
      padding: AppPaddings.panelCompanyBox,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.panelControlAll,
        border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
      ),
      child: Text(
        name,
        style: PanelTextStyles.bodyStrong,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.target,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final String target;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Padding(
      padding: AppPaddings.navItemGap,
      child: Material(
        color: selected ? AppColors.primaryTint : AppColors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.panelControlAll),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(borderRadius: AppRadius.panelControlAll),
          hoverColor: AppColors.background,
          onTap: () => context.go(target),
          child: SizedBox(
            height: AppSizes.panelControlHeight,
            child: Padding(
              padding: AppPaddings.panelNavItem,
              child: Row(
                children: [
                  Icon(icon, size: AppSizes.iconMd, color: color),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: (selected ? PanelTextStyles.bodyStrong : PanelTextStyles.body)
                          .copyWith(color: selected ? AppColors.primary : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
