import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/widgets/panel_page.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../tickets/presentation/widgets/participants_dialog.dart';
import '../../domain/entities/departure.dart';
import '../utils/departure_display.dart';
import '../cubit/departures_cubit.dart';
import 'departure_form_dialog.dart';

/// Turun tarihleri: ekleme, düzenleme (kontenjan, rehber, araç), silme.
class DeparturesPanel extends StatelessWidget {
  const DeparturesPanel({super.key});

  Future<void> _openForm(BuildContext context, {Departure? departure}) async {
    final cubit = context.read<DeparturesCubit>();
    final state = cubit.state;
    await showDepartureFormDialog(
      context,
      title: departure == null ? AppStrings.newDeparture : AppStrings.editDeparture,
      initial: departure,
      guides: state.assignableGuides,
      currentGuideName: state.guideName(departure?.guideId),
      onSubmit: (draft) =>
          departure == null ? cubit.create(draft) : cubit.update(departure.id, draft),
    );
  }

  Future<void> _openParticipants(BuildContext context, Departure departure) async {
    final cubit = context.read<DeparturesCubit>();
    final soldSeats = await showParticipantsDialog(
      context,
      companyId: cubit.companyId,
      departure: departure,
    );
    if (soldSeats != null) cubit.setSoldSeats(departure.id, soldSeats);
  }

  Future<void> _delete(BuildContext context, Departure departure) async {
    final cubit = context.read<DeparturesCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteConfirmTitle,
      message: '${Formatters.dateTime(departure.departureAt)}\n${AppStrings.deleteConfirmMessage}',
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed) return;
    final result = await cubit.delete(departure.id);
    if (context.mounted) {
      showMessage(context, result.isSuccess ? AppStrings.deleted : result.failure!.message);
    }
  }

  Future<void> _cancel(BuildContext context, Departure departure) async {
    final cubit = context.read<DeparturesCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.cancelDepartureTitle,
      message:
          '${Formatters.dateTime(departure.departureAt)}\n${AppStrings.cancelDepartureMessage}',
      confirmLabel: AppStrings.cancelDepartureConfirm,
      isDestructive: true,
    );
    if (!confirmed) return;
    final result = await cubit.cancel(departure.id);
    if (context.mounted) {
      showMessage(context, result.isSuccess ? result.value!.summary : result.failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DeparturesCubit>().state;
    final now = DateTime.now();

    return switch (state.status) {
      LoadStatus.initial || LoadStatus.loading => const StatusView.loading(),
      LoadStatus.failure => StatusView.message(
        message: state.loadFailure!.message,
        onAction: context.read<DeparturesCubit>().load,
      ),
      LoadStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppPaddings.verticalLg,
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: state.isBusy ? null : () => _openForm(context),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.newDeparture),
              ),
            ),
          ),
          Expanded(
            child: state.departures.isEmpty
                ? const StatusView.message(message: AppStrings.departuresEmpty)
                : SingleChildScrollView(
                    child: PanelTableCard(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text(AppStrings.departureDate)),
                          DataColumn(label: Text(AppStrings.seatsColumn)),
                          DataColumn(label: Text(AppStrings.departureGuide)),
                          DataColumn(label: Text(AppStrings.busPlate)),
                          DataColumn(label: Text(AppStrings.statusColumn)),
                          DataColumn(label: SizedBox.shrink()),
                        ],
                        rows: [
                          for (final departure in state.departures)
                            DataRow(
                              cells: [
                                DataCell(Text(Formatters.dateTime(departure.departureAt))),
                                DataCell(Text('${departure.soldSeats} / ${departure.capacity}')),
                                DataCell(
                                  Text(state.guideName(departure.guideId) ?? AppStrings.noGuide),
                                ),
                                DataCell(Text(departure.busPlate ?? AppStrings.empty)),
                                DataCell(
                                  ToneBadge(
                                    label: departure.status.label,
                                    tone: departure.status.tone,
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: state.isBusy
                                            ? null
                                            : () => _openParticipants(context, departure),
                                        icon: const Icon(Icons.people_outline),
                                        tooltip: AppStrings.participants,
                                      ),
                                      IconButton(
                                        onPressed: state.isBusy || !departure.isEditable
                                            ? null
                                            : () => _openForm(context, departure: departure),
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: departure.isEditable
                                            ? AppStrings.edit
                                            : AppStrings.departureLocked,
                                      ),
                                      if (departure.canBeCancelledAt(now))
                                        IconButton(
                                          onPressed: state.isBusy
                                              ? null
                                              : () => _cancel(context, departure),
                                          icon: const Icon(Icons.event_busy_outlined),
                                          tooltip: AppStrings.cancelDeparture,
                                        ),
                                      IconButton(
                                        onPressed: state.isBusy
                                            ? null
                                            : () => _delete(context, departure),
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
          ),
        ],
      ),
    };
  }
}
