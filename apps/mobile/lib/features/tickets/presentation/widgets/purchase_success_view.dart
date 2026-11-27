import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/status_circle.dart';
import '../../domain/entities/ticket.dart';
import '../utils/ticket_display.dart';
import 'ticket_qr_card.dart';

/// Satın alma sonrası: başarı işareti, basılı bilet görünümünde QR, Turlarım'a geçiş.
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
    return SafeArea(
      child: ListView(
        padding: AppPaddings.successPage,
        children: [
          const Center(
            child: StatusCircle(icon: Icons.check_circle, tone: AppTone.success),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.purchaseSuccessTitle,
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.purchaseSuccessMessage,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          TicketQrCard(
            qrToken: ticket.qrToken,
            title: ticket.tourTitle,
            subtitle: ticket.departureLabel,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(onPressed: onMyTickets, child: const Text(AppStrings.goToMyTickets)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onBackToTours, child: const Text(AppStrings.backToTours)),
        ],
      ),
    );
  }
}
