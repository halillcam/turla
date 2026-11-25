import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/stale_data_banner.dart';
import '../../../../core/widgets/status_view.dart';
import '../../domain/entities/ticket.dart';
import '../cubit/my_tickets_cubit.dart';
import 'ticket_tile.dart';

/// Aşağı çekince yenilenen bilet listesi (Yaklaşan / Geçmiş).
class MyTicketsList extends StatelessWidget {
  const MyTicketsList({
    required this.state,
    required this.onRefresh,
    required this.onTicketTap,
    required this.onBrowseTours,
    super.key,
  });

  final MyTicketsState state;
  final Future<void> Function() onRefresh;
  final ValueChanged<Ticket> onTicketTap;
  final VoidCallback onBrowseTours;

  @override
  Widget build(BuildContext context) {
    if (state.status == MyTicketsStatus.loading) return const StatusView.loading();
    if (state.status == MyTicketsStatus.failure) {
      return StatusView.message(
        message: AppStrings.ticketsLoadError,
        icon: Icons.wifi_off,
        onAction: onRefresh,
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final upcoming = state.upcoming;
    final past = state.past;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppPaddings.screen,
        children: [
          if (state.isStale) const StaleDataBanner(message: AppStrings.showingCachedTickets),
          if (state.tickets.isEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            StatusView.message(
              message: AppStrings.noTickets,
              icon: Icons.confirmation_number_outlined,
              onAction: onBrowseTours,
              actionLabel: AppStrings.browseTours,
            ),
          ] else ...[
            Text(AppStrings.upcomingTickets, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (upcoming.isEmpty)
              Padding(
                padding: AppPaddings.verticalSm,
                child: Text(AppStrings.noUpcomingTickets, style: textTheme.bodyMedium),
              ),
            for (final ticket in upcoming)
              TicketTile(ticket: ticket, onTap: () => onTicketTap(ticket)),
            if (past.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(AppStrings.pastTickets, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final ticket in past)
                TicketTile(ticket: ticket, onTap: () => onTicketTap(ticket)),
            ],
          ],
        ],
      ),
    );
  }
}
