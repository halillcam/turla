import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/panel_page.dart';
import '../../../../core/widgets/status_view.dart';
import '../../domain/entities/staff_member.dart';
import '../cubit/staff_cubit.dart';
import '../widgets/account_form_dialog.dart';
import '../widgets/member_table.dart';

/// Tur sorumluları ve dışarıdan eklenen müşteriler.
class StaffScreen extends StatelessWidget {
  const StaffScreen({required this.companyId, super.key});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StaffCubit>(param1: companyId)..load(),
      child: const _StaffView(),
    );
  }
}

class _StaffView extends StatelessWidget {
  const _StaffView();

  Future<void> _create(BuildContext context, UserRole role) async {
    final cubit = context.read<StaffCubit>();
    final created = await showAccountFormDialog(
      context,
      title: role == UserRole.guide ? AppStrings.newGuide : AppStrings.newCustomer,
      withEmail: false,
      onSubmit: (values) => cubit.create(
        role: role,
        fullName: values.fullName,
        password: values.password,
        phone: values.phone,
      ),
    );
    if (created != null && context.mounted) await showCreatedAccountDialog(context, created);
  }

  Future<void> _toggle(BuildContext context, StaffCubit cubit, StaffMember member) async {
    final result = await cubit.toggleActive(member);
    if (!result.isSuccess && context.mounted) showMessage(context, result.failure!.message);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StaffCubit>().state;
    final cubit = context.read<StaffCubit>();

    return DefaultTabController(
      length: 2,
      child: PanelPage(
        title: AppStrings.staffTitle,
        actions: [
          OutlinedButton.icon(
            onPressed: state.isBusy ? null : () => _create(context, UserRole.customer),
            icon: const Icon(Icons.person_add_alt),
            label: const Text(AppStrings.newCustomer),
          ),
          FilledButton.icon(
            onPressed: state.isBusy ? null : () => _create(context, UserRole.guide),
            icon: const Icon(Icons.badge_outlined),
            label: const Text(AppStrings.newGuide),
          ),
        ],
        child: switch (state.status) {
          LoadStatus.initial || LoadStatus.loading => const StatusView.loading(),
          LoadStatus.failure => StatusView.message(
            message: state.loadFailure!.message,
            onAction: cubit.load,
          ),
          LoadStatus.ready => Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: AppStrings.guidesTab),
                  Tab(text: AppStrings.customersTab),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    MemberTable(
                      members: state.guides,
                      emptyMessage: AppStrings.guidesEmpty,
                      enabled: !state.isBusy,
                      onToggleActive: (m) => _toggle(context, cubit, m),
                    ),
                    MemberTable(
                      members: state.customers,
                      emptyMessage: AppStrings.customersEmpty,
                      enabled: !state.isBusy,
                      onToggleActive: (m) => _toggle(context, cubit, m),
                    ),
                  ],
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
