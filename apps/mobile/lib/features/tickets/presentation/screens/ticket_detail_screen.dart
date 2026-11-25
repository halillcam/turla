import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/status_view.dart';
import '../cubit/ticket_detail_cubit.dart';
import '../utils/ticket_failure_message.dart';
import '../widgets/cancel_ticket_dialog.dart';
import '../widgets/ticket_detail_view.dart';

/// Bilet detayı. Cihazdaki kayıttan açılır; QR internetsiz görünür.
class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({required this.ticketId, super.key});

  final String ticketId;

  Future<void> _onCancel(BuildContext context) async {
    final cubit = context.read<TicketDetailCubit>();
    final ticket = cubit.state.ticket;
    if (ticket == null) return;
    if (await CancelTicketDialog.show(context, ticket)) await cubit.cancel();
  }

  void _showResult(BuildContext context, TicketDetailState state) {
    final message = switch (state.cancelStatus) {
      CancelStatus.success => AppStrings.ticketCancelledMessage,
      CancelStatus.failure => state.failure?.message,
      _ => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TicketDetailCubit>()..load(ticketId),
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.ticketDetailTitle)),
        body: BlocConsumer<TicketDetailCubit, TicketDetailState>(
          listenWhen: (previous, current) => previous.cancelStatus != current.cancelStatus,
          listener: _showResult,
          builder: (context, state) => switch (state.status) {
            TicketDetailStatus.loading => const StatusView.loading(),
            TicketDetailStatus.notFound => const StatusView.message(
              message: AppStrings.ticketNotFound,
              icon: Icons.error_outline,
            ),
            TicketDetailStatus.ready => TicketDetailView(
              ticket: state.ticket!,
              canCancel: state.canCancel,
              isCancelling: state.cancelStatus == CancelStatus.inProgress,
              onCancel: () => _onCancel(context),
            ),
          },
        ),
      ),
    );
  }
}
