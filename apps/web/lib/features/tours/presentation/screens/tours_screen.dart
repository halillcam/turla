import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/panel_page.dart';
import '../../../../core/widgets/status_view.dart';
import '../../domain/entities/managed_tour.dart';
import '../cubit/tour_list_cubit.dart';

/// Firmanın turları.
class ToursScreen extends StatelessWidget {
  const ToursScreen({required this.companyId, super.key});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TourListCubit>(param1: companyId)..load(),
      child: _ToursView(companyId: companyId),
    );
  }
}

class _ToursView extends StatelessWidget {
  const _ToursView({required this.companyId});

  final String companyId;

  Future<void> _delete(BuildContext context, ManagedTour tour) async {
    final cubit = context.read<TourListCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteConfirmTitle,
      message: '${tour.title}\n${AppStrings.deleteConfirmMessage}',
      confirmLabel: AppStrings.delete,
    );
    if (!confirmed) return;
    final result = await cubit.delete(tour);
    if (context.mounted) {
      showMessage(context, result.isSuccess ? AppStrings.deleted : result.failure!.message);
    }
  }

  Future<void> _toggle(BuildContext context, ManagedTour tour) async {
    final result = await context.read<TourListCubit>().toggleActive(tour);
    if (!result.isSuccess && context.mounted) showMessage(context, result.failure!.message);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TourListCubit>().state;

    return PanelPage(
      title: AppStrings.toursTitle,
      actions: [
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.newTour(companyId)),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.newTour),
        ),
      ],
      child: switch (state.status) {
        LoadStatus.initial || LoadStatus.loading => const StatusView.loading(),
        LoadStatus.failure => StatusView.message(
          message: state.loadFailure!.message,
          onAction: context.read<TourListCubit>().load,
        ),
        LoadStatus.ready when state.tours.isEmpty => const StatusView.message(
          message: AppStrings.toursEmpty,
        ),
        LoadStatus.ready => SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text(AppStrings.tourTitle)),
                DataColumn(label: Text(AppStrings.tourRegion)),
                DataColumn(label: Text(AppStrings.priceColumn)),
                DataColumn(label: Text(AppStrings.departuresColumn)),
                DataColumn(label: Text(AppStrings.statusColumn)),
                DataColumn(label: SizedBox.shrink()),
              ],
              rows: [
                for (final tour in state.tours)
                  DataRow(
                    onSelectChanged: (_) => context.go(AppRoutes.tour(companyId, tour.id)),
                    cells: [
                      DataCell(Text(tour.title)),
                      DataCell(Text(tour.region.label)),
                      DataCell(Text(Formatters.price(tour.price))),
                      DataCell(Text('${tour.departureCount}')),
                      DataCell(
                        ActiveChip(
                          isActive: tour.isActive,
                          activeLabel: AppStrings.active,
                          passiveLabel: AppStrings.passive,
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: state.isBusy ? null : () => _toggle(context, tour),
                              child: Text(
                                tour.isActive ? AppStrings.makePassive : AppStrings.makeActive,
                              ),
                            ),
                            IconButton(
                              onPressed: state.isBusy ? null : () => _delete(context, tour),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: AppStrings.delete,
                            ),
                          ],
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
