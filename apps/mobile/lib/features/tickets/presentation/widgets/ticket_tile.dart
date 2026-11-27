import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../tours/presentation/widgets/tour_image.dart';
import '../../domain/entities/ticket.dart';
import '../utils/ticket_display.dart';
import 'ticket_status_chip.dart';

/// Turlarım listesindeki bilet satırı: küçük görsel, tur, tarih, firma ve durum.
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
        onTap: onTap,
        child: Padding(
          padding: AppPaddings.allMd,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.mdPlusAll,
                child: SizedBox.square(
                  dimension: AppSizes.thumbnail,
                  child: TourImage(imageUrl: ticket.tourImageUrl),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.tourTitle, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      ticket.shortDepartureLabel,
                      style: textTheme.bodySmall?.copyWith(
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
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
