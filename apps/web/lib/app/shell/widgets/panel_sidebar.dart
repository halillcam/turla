import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../core/constants/strings.dart';
import '../../router/app_routes.dart';

/// Sol menü. Super admin firmalar listesini; firma alanında turlar, personel ve
/// tur bitirme talepleri görünür.
class PanelSidebar extends StatelessWidget {
  const PanelSidebar({
    required this.location,
    required this.companyId,
    required this.showCompanies,
    super.key,
  });

  final String location;
  final String? companyId;
  final bool showCompanies;

  @override
  Widget build(BuildContext context) {
    final id = companyId;
    return SizedBox(
      width: AppSizes.sidebarWidth,
      child: ListView(
        padding: AppPaddings.verticalLg,
        children: [
          Padding(
            padding: AppPaddings.horizontalLg,
            child: Text(AppStrings.panelTitle, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (showCompanies)
            _item(
              context,
              icon: Icons.business_outlined,
              label: id == null ? AppStrings.navCompanies : AppStrings.backToCompanies,
              target: AppRoutes.companies,
              selected: location.startsWith(AppRoutes.companies),
            ),
          if (showCompanies && id == null) ...[
            _item(
              context,
              icon: Icons.campaign_outlined,
              label: AppStrings.navAnnouncements,
              target: AppRoutes.announcements,
              selected: location.startsWith(AppRoutes.announcements),
            ),
            _item(
              context,
              icon: Icons.feedback_outlined,
              label: AppStrings.navFeedback,
              target: AppRoutes.feedback,
              selected: location.startsWith(AppRoutes.feedback),
            ),
          ],
          if (id != null) ...[
            _item(
              context,
              icon: Icons.map_outlined,
              label: AppStrings.navTours,
              target: AppRoutes.tours(id),
              selected: location.startsWith(AppRoutes.tours(id)),
            ),
            _item(
              context,
              icon: Icons.badge_outlined,
              label: AppStrings.navStaff,
              target: AppRoutes.staff(id),
              selected: location.startsWith(AppRoutes.staff(id)),
            ),
            _item(
              context,
              icon: Icons.task_alt_outlined,
              label: AppStrings.navCompletions,
              target: AppRoutes.completions(id),
              selected: location.startsWith(AppRoutes.completions(id)),
            ),
            _item(
              context,
              icon: Icons.campaign_outlined,
              label: AppStrings.navAnnouncements,
              target: AppRoutes.companyAnnouncements(id),
              selected: location.startsWith(AppRoutes.companyAnnouncements(id)),
            ),
            _item(
              context,
              icon: Icons.feedback_outlined,
              label: AppStrings.navFeedback,
              target: AppRoutes.companyFeedback(id),
              selected: location.startsWith(AppRoutes.companyFeedback(id)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String target,
    required bool selected,
  }) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    selected: selected,
    onTap: () => context.go(target),
  );
}
