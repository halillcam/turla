import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/ticket.dart';
import '../utils/ticket_display.dart';
import 'ticket_status_chip.dart';

/// Turlarım listesindeki bilet satırı.
class TicketTile extends StatelessWidget {
  const TicketTile({required this.ticket, required this.onTap, super.key});

  final Ticket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: AppMargins.cardList,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: AppPaddings.card,
          child: Row(
            children: [
              Icon(
                ticket.showsQr ? Icons.qr_code_2 : Icons.confirmation_number_outlined,
                size: AppSizes.iconXl,
                color: ticket.isActive ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.tourTitle, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(ticket.shortDepartureLabel, style: textTheme.bodySmall),
                    Text(ticket.companyName, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TicketStatusChip(status: ticket.status),
            ],
          ),
        ),
      ),
    );
  }
}
