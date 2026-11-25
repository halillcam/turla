import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/phone_launcher.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/stale_data_banner.dart';
import '../../../../core/widgets/status_view.dart';
import '../../domain/entities/participant.dart';
import '../cubit/departure_cubit.dart';
import '../utils/guide_display.dart';
import '../widgets/departure_header.dart';
import '../widgets/participant_filter_bar.dart';
import '../widgets/participant_tile.dart';

/// Bir kalkışın katılımcıları: geldi/gelmedi, arama, elle "Geldi", QR okut, turu bitir.
class DepartureScreen extends StatelessWidget {
  const DepartureScreen({required this.departureId, super.key});

  final String departureId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DepartureCubit>()..load(departureId),
      child: const _DepartureView(),
    );
  }
}

class _DepartureView extends StatelessWidget {
  const _DepartureView();

  Future<void> _openScanner(BuildContext context, String departureId) async {
    final cubit = context.read<DepartureCubit>();
    await context.push(AppRoutes.guideScanOf(departureId));
    // Okutmalar cihazdaki listeye yazıldı; yeniden istek atılmaz.
    if (!cubit.isClosed) await cubit.reloadFromDevice();
  }

  Future<void> _confirmCheckIn(BuildContext context, Participant participant) async {
    final cubit = context.read<DepartureCubit>();
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.manualCheckInTitle,
      message: '${participant.passengerName}\n\n${AppStrings.manualCheckInMessage}',
      confirmLabel: AppStrings.manualCheckInConfirm,
    );
    if (confirmed) await cubit.checkInManually(participant);
  }

  Future<void> _confirmFinish(BuildContext context) async {
    final cubit = context.read<DepartureCubit>();
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.finishTourTitle,
      message: AppStrings.finishTourMessage,
      confirmLabel: AppStrings.finishTourConfirm,
    );
    if (confirmed) await cubit.requestCompletion();
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DepartureCubit, DepartureState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus ||
          (current.lastCheckIn != null && previous.lastCheckIn != current.lastCheckIn),
      listener: (context, state) {
        final cubit = context.read<DepartureCubit>();
        final result = state.lastCheckIn;
        if (state.actionStatus == DepartureAction.failure) {
          _showMessage(context, (state.actionFailure ?? state.failure)?.message ?? '');
          cubit.clearAction();
        } else if (state.actionStatus == DepartureAction.completionRequested) {
          _showMessage(context, AppStrings.finishTourSent);
          cubit.clearAction();
        } else if (result != null && state.actionStatus == DepartureAction.idle) {
          _showMessage(
            context,
            result.isSuccess
                ? '${AppStrings.manualCheckInDone} ${result.passengerName ?? ''}'
                : '${result.title}: ${result.message}',
          );
        }
      },
      builder: (context, state) {
        final departure = state.departure;
        return Scaffold(
          appBar: AppBar(title: Text(departure?.tourTitle ?? AppStrings.participantsTitle)),
          body: SafeArea(child: _body(context, state)),
          bottomNavigationBar: departure == null ? null : _actions(context, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, DepartureState state) {
    final cubit = context.read<DepartureCubit>();
    final departure = state.departure;
    if (state.status == DepartureViewStatus.notFound) {
      return const StatusView.message(
        message: AppStrings.departureNotFound,
        icon: Icons.event_busy,
      );
    }
    if (departure == null) {
      return state.status == DepartureViewStatus.failure
          ? StatusView.message(
              message: AppStrings.participantsLoadError,
              icon: Icons.wifi_off,
              onAction: cubit.refresh,
            )
          : const StatusView.loading();
    }

    final participants = state.visibleParticipants;
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        padding: AppPaddings.screen,
        children: [
          if (state.isStale) const StaleDataBanner(message: AppStrings.showingCachedParticipants),
          DepartureHeader(
            departure: departure,
            arrived: state.arrivedCount,
            notArrived: state.notArrivedCount,
            onCallDriver: () => PhoneLauncher.call(departure.driverPhone ?? ''),
          ),
          const SizedBox(height: AppSpacing.lg),
          ParticipantFilterBar(
            filter: state.filter,
            onFilterChanged: cubit.setFilter,
            onSearchChanged: cubit.search,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.status == DepartureViewStatus.loading)
            const Padding(padding: AppPaddings.allXl, child: StatusView.loading())
          else if (state.status == DepartureViewStatus.failure)
            StatusView.message(
              message: AppStrings.participantsLoadError,
              icon: Icons.wifi_off,
              onAction: cubit.refresh,
            )
          else if (participants.isEmpty)
            StatusView.message(
              message: state.participants.isEmpty
                  ? AppStrings.noParticipants
                  : AppStrings.noParticipantsMatch,
              icon: Icons.people_outline,
            )
          else
            for (final participant in participants)
              ParticipantTile(
                participant: participant,
                onCheckIn: state.canCheckIn ? () => _confirmCheckIn(context, participant) : null,
                onCall: () => PhoneLauncher.call(participant.phone ?? ''),
              ),
        ],
      ),
    );
  }

  Widget? _actions(BuildContext context, DepartureState state) {
    final departure = state.departure!;
    final busy = state.actionStatus == DepartureAction.inProgress;
    if (!state.canCheckIn) return null;
    return SafeArea(
      child: Padding(
        padding: AppPaddings.screen,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: busy ? null : () => _openScanner(context, departure.id),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(AppStrings.scanQr),
              ),
            ),
            if (state.canRequestCompletion) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _confirmFinish(context),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text(AppStrings.finishTour),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
