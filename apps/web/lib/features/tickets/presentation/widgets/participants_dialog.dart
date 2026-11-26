import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../chat/presentation/widgets/departure_chat_dialog.dart';
import '../../../tours/domain/entities/departure.dart';
import '../../domain/entities/participant_ticket.dart';
import '../cubit/participants_cubit.dart';
import 'issue_ticket_dialog.dart';
import 'participants_table.dart';

/// Tarihin katılımcı / bilet penceresi. Kapanınca güncel satılan koltuk sayısını
/// döndürür (liste yüklenemediyse null); tarih tablosu buna göre yerelde güncellenir.
Future<int?> showParticipantsDialog(
  BuildContext context, {
  required String companyId,
  required Departure departure,
}) => showDialog<int?>(
  context: context,
  builder: (_) => BlocProvider(
    create: (_) => getIt<ParticipantsCubit>(param1: companyId, param2: departure)..load(),
    child: const _ParticipantsDialog(),
  ),
);

class _ParticipantsDialog extends StatelessWidget {
  const _ParticipantsDialog();

  Future<void> _issue(BuildContext context) async {
    final cubit = context.read<ParticipantsCubit>();
    await showIssueTicketDialog(
      context,
      customers: cubit.state.customers,
      onSubmit: (customerId, passengerName) async {
        final result = await cubit.issue(customerId: customerId, passengerName: passengerName);
        if (result.isSuccess && context.mounted) showMessage(context, AppStrings.ticketIssued);
        return result;
      },
    );
  }

  Future<void> _cancel(BuildContext context, ParticipantTicket ticket) async {
    final cubit = context.read<ParticipantsCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.cancelTicketTitle,
      message: '${ticket.passengerName}\n\n${AppStrings.cancelTicketMessage}',
      confirmLabel: AppStrings.cancelTicket,
    );
    if (!confirmed) return;
    final result = await cubit.cancel(ticket.id);
    if (context.mounted) {
      showMessage(context, result.isSuccess ? AppStrings.ticketCancelled : result.failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ParticipantsCubit>();
    final state = context.watch<ParticipantsCubit>().state;
    final departure = cubit.departure;
    final isReady = state.status == LoadStatus.ready;
    final canIssue = isReady && !state.isBusy && departure.status == DepartureStatus.scheduled;

    return AlertDialog(
      title: Text(
        '${AppStrings.participantsTitle} · ${Formatters.dateTime(departure.departureAt)}',
      ),
      content: SizedBox(
        width: AppSizes.wideDialogWidth,
        height: AppSizes.wideDialogHeight,
        child: switch (state.status) {
          LoadStatus.initial || LoadStatus.loading => const StatusView.loading(),
          LoadStatus.failure => StatusView.message(
            message: state.loadFailure!.message,
            onAction: cubit.load,
          ),
          LoadStatus.ready => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.soldSeatsLabel}: ${state.soldSeats} / ${departure.capacity}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showDepartureChatDialog(context, departure: departure),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text(AppStrings.chatButton),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Tooltip(
                    message: departure.status == DepartureStatus.scheduled
                        ? AppStrings.issueTicketHint
                        : AppStrings.issueTicketClosed,
                    child: FilledButton.icon(
                      onPressed: canIssue ? () => _issue(context) : null,
                      icon: const Icon(Icons.add),
                      label: const Text(AppStrings.issueTicket),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: state.tickets.isEmpty
                    ? const StatusView.message(message: AppStrings.participantsEmpty)
                    : ParticipantsTable(
                        tickets: state.sortedTickets,
                        canCancel: !state.isBusy && departure.isEditable,
                        onCancel: (ticket) => _cancel(context, ticket),
                      ),
              ),
            ],
          ),
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, isReady ? state.soldSeats : null),
          child: const Text(AppStrings.close),
        ),
      ],
    );
  }
}
