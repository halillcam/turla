import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../../../../core/widgets/stale_data_banner.dart';
import '../../../../core/widgets/status_view.dart';
import '../../domain/entities/ticket.dart';
import '../cubit/my_tickets_cubit.dart';
import 'ticket_tile.dart';

/// Yaklaşan / Geçmiş sekmeli, aşağı çekince yenilenen bilet listesi.
/// Seçili sekme sadece görünüm durumudur; listeler state'ten gelir.
class MyTicketsList extends StatefulWidget {
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
  State<MyTicketsList> createState() => _MyTicketsListState();
}

class _MyTicketsListState extends State<MyTicketsList> {
  static const int _upcomingTab = 0;
  int _tab = _upcomingTab;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.status == MyTicketsStatus.loading) return const StatusView.loading();
    if (state.status == MyTicketsStatus.failure) {
      return StatusView.message(
        message: AppStrings.ticketsLoadError,
        icon: Icons.wifi_off,
        onAction: widget.onRefresh,
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final showsUpcoming = _tab == _upcomingTab;
    final tickets = showsUpcoming ? state.upcoming : state.past;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppPaddings.listBody,
        children: [
          if (state.isStale) const StaleDataBanner(message: AppStrings.showingCachedTickets),
          if (state.tickets.isEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            StatusView.message(
              message: AppStrings.noTickets,
              icon: Icons.confirmation_number_outlined,
              onAction: widget.onBrowseTours,
              actionLabel: AppStrings.browseTours,
            ),
          ] else ...[
            SegmentedTabs(
              labels: const [AppStrings.upcomingTickets, AppStrings.pastTickets],
              selectedIndex: _tab,
              onChanged: (index) => setState(() => _tab = index),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (tickets.isEmpty)
              Padding(
                padding: AppPaddings.verticalLg,
                child: Text(
                  showsUpcoming ? AppStrings.noUpcomingTickets : AppStrings.noPastTickets,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            for (final ticket in tickets)
              TicketTile(ticket: ticket, onTap: () => widget.onTicketTap(ticket)),
          ],
        ],
      ),
    );
  }
}
