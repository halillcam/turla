import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/ticket.dart';
import '../utils/ticket_display.dart';
import 'ticket_qr_card.dart';

/// Satın alma sonrası: QR, tur ve tarih özeti, Turlarım'a geçiş.
class PurchaseSuccessView extends StatelessWidget {
  const PurchaseSuccessView({
    required this.ticket,
    required this.onMyTickets,
    required this.onBackToTours,
    super.key,
  });

  final Ticket ticket;
  final VoidCallback onMyTickets;
  final VoidCallback onBackToTours;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: AppPaddings.screen,
      children: [
        const Icon(Icons.check_circle, size: AppSizes.avatarMd, color: AppColors.success),
        const SizedBox(height: AppSpacing.md),
        Text(ticket.tourTitle, style: textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(ticket.departureLabel, style: textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        TicketQrCard(qrToken: ticket.qrToken),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppStrings.purchaseSuccessMessage,
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(onPressed: onMyTickets, child: const Text(AppStrings.goToMyTickets)),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(onPressed: onBackToTours, child: const Text(AppStrings.backToTours)),
      ],
    );
  }
}
