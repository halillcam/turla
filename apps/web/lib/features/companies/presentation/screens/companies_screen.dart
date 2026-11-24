import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/panel_page.dart';
import '../../../../core/widgets/status_view.dart';
import '../cubit/company_list_cubit.dart';
import '../widgets/company_form_dialog.dart';

/// Super admin: firma listesi.
class CompaniesScreen extends StatelessWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CompanyListCubit>()..load(),
      child: const _CompaniesView(),
    );
  }
}

class _CompaniesView extends StatelessWidget {
  const _CompaniesView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CompanyListCubit>().state;
    final cubit = context.read<CompanyListCubit>();
    final cityNames = {for (final city in state.cities) city.id: city.name};

    return PanelPage(
      title: AppStrings.companiesTitle,
      actions: [
        FilledButton.icon(
          onPressed: state.status != LoadStatus.ready || state.isBusy
              ? null
              : () => showCompanyFormDialog(
                  context,
                  title: AppStrings.newCompany,
                  cities: state.cities,
                  onSubmit: cubit.create,
                ),
          icon: const Icon(Icons.add_business_outlined),
          label: const Text(AppStrings.newCompany),
        ),
      ],
      child: switch (state.status) {
        LoadStatus.initial || LoadStatus.loading => const StatusView.loading(),
        LoadStatus.failure => StatusView.message(
          message: state.loadFailure!.message,
          onAction: cubit.load,
        ),
        LoadStatus.ready when state.companies.isEmpty => const StatusView.message(
          message: AppStrings.companiesEmpty,
        ),
        LoadStatus.ready => SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text(AppStrings.companyName)),
                DataColumn(label: Text(AppStrings.companyCity)),
                DataColumn(label: Text(AppStrings.companyPhone)),
                DataColumn(label: Text(AppStrings.statusColumn)),
                DataColumn(label: SizedBox.shrink()),
              ],
              rows: [
                for (final company in state.companies)
                  DataRow(
                    onSelectChanged: (_) => context.go(AppRoutes.companyDetail(company.id)),
                    cells: [
                      DataCell(Text(company.name)),
                      DataCell(Text(cityNames[company.cityId] ?? AppStrings.empty)),
                      DataCell(Text(company.phone ?? AppStrings.empty)),
                      DataCell(
                        ActiveChip(
                          isActive: company.isActive,
                          activeLabel: AppStrings.active,
                          passiveLabel: AppStrings.passive,
                        ),
                      ),
                      DataCell(
                        TextButton(
                          onPressed: state.isBusy
                              ? null
                              : () async {
                                  final result = await cubit.toggleActive(company);
                                  if (!result.isSuccess && context.mounted) {
                                    showMessage(context, result.failure!.message);
                                  }
                                },
                          child: Text(
                            company.isActive ? AppStrings.makePassive : AppStrings.makeActive,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      },
    );
  }
}
