import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/panel_page.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../staff/presentation/widgets/account_form_dialog.dart';
import '../../../staff/presentation/widgets/member_table.dart';
import '../cubit/company_detail_cubit.dart';
import '../widgets/company_form_dialog.dart';

/// Super admin: firma bilgisi, aktif/pasif, firma yöneticileri.
class CompanyDetailScreen extends StatelessWidget {
  const CompanyDetailScreen({required this.companyId, super.key});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CompanyDetailCubit>(param1: companyId)..load(),
      child: const _CompanyDetailView(),
    );
  }
}

class _CompanyDetailView extends StatelessWidget {
  const _CompanyDetailView();

  Future<void> _createAdmin(BuildContext context, CompanyDetailCubit cubit) async {
    final created = await showAccountFormDialog(
      context,
      title: AppStrings.newAdmin,
      withEmail: true,
      onSubmit: (values) => cubit.createAdmin(
        fullName: values.fullName,
        email: values.email!,
        password: values.password,
        phone: values.phone,
      ),
    );
    if (created != null && context.mounted) await showCreatedAccountDialog(context, created);
  }

  Future<void> _show(BuildContext context, Future<ActionResult<Object?>> action) async {
    final result = await action;
    if (!result.isSuccess && context.mounted) showMessage(context, result.failure!.message);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CompanyDetailCubit>().state;
    final cubit = context.read<CompanyDetailCubit>();
    final company = state.company;

    if (state.status == LoadStatus.failure) {
      return StatusView.message(message: state.loadFailure!.message, onAction: cubit.load);
    }
    if (company == null) return const StatusView.loading();

    final cityName = state.cities.where((c) => c.id == company.cityId).firstOrNull?.name;
    final textTheme = Theme.of(context).textTheme;

    return PanelPage(
      title: company.name,
      actions: [
        OutlinedButton(
          onPressed: state.isBusy
              ? null
              : () => showCompanyFormDialog(
                  context,
                  title: AppStrings.editCompany,
                  cities: state.cities,
                  initial: company,
                  onSubmit: cubit.update,
                ),
          child: const Text(AppStrings.edit),
        ),
        OutlinedButton(
          onPressed: state.isBusy ? null : () => _show(context, cubit.toggleActive()),
          child: Text(company.isActive ? AppStrings.makePassive : AppStrings.makeActive),
        ),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.tours(company.id)),
          icon: const Icon(Icons.arrow_forward),
          label: const Text(AppStrings.manageCompany),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.lg,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActiveChip(
                isActive: company.isActive,
                activeLabel: AppStrings.active,
                passiveLabel: AppStrings.passive,
              ),
              Text('${AppStrings.companyCity}: ${cityName ?? AppStrings.empty}'),
              Text('${AppStrings.companyPhone}: ${company.phone ?? AppStrings.empty}'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: Text(AppStrings.companyAdmins, style: textTheme.titleMedium)),
              FilledButton.icon(
                onPressed: state.isBusy ? null : () => _createAdmin(context, cubit),
                icon: const Icon(Icons.person_add_alt),
                label: const Text(AppStrings.newAdmin),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: MemberTable(
              members: state.admins,
              emptyMessage: AppStrings.companyAdminsEmpty,
              showLoginId: false,
              emails: state.adminEmails,
              enabled: !state.isBusy,
              onToggleActive: (admin) => _show(context, cubit.toggleAdminActive(admin)),
            ),
          ),
        ],
      ),
    );
  }
}
