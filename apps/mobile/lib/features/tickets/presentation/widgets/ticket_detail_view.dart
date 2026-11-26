import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../domain/entities/ticket.dart';
import '../utils/ticket_display.dart';
import '../../../../core/widgets/info_row.dart';
import 'ticket_qr_card.dart';
import 'ticket_status_chip.dart';

/// Bilet detayı: QR, tarih/saat, araç, firma telefonu ve iptal alanı.
class TicketDetailView extends StatelessWidget {
  const TicketDetailView({
    required this.ticket,
    required this.canCancel,
    required this.isCancelling,
    required this.onCancel,
    required this.onOpenActiveTour,
    super.key,
  });

  final Ticket ticket;
  final bool canCancel;
  final bool isCancelling;
  final VoidCallback onCancel;

  /// Geçerli bilette aktif tur ekranını açar (tur sorumlusu, sohbet, duyurular).
  final VoidCallback onOpenActiveTour;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final refundLabel = ticket.refundLabel;
    final cancelledAtLabel = ticket.cancelledAtLabel;

    return ListView(
      padding: AppPaddings.screen,
      children: [
        Row(
          children: [
            Expanded(child: Text(ticket.tourTitle, style: textTheme.titleLarge)),
            const SizedBox(width: AppSpacing.sm),
            TicketStatusChip(status: ticket.status),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (ticket.showsQr) ...[
          TicketQrCard(qrToken: ticket.qrToken),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (ticket.isActive) ...[
          ElevatedButton.icon(
            onPressed: onOpenActiveTour,
            icon: const Icon(Icons.tour_outlined),
            label: const Text(AppStrings.activeTourButton),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (ticket.showsScannedNotice)
          InfoBanner(
            message: '${ticket.scannedLabel}\n${AppStrings.qrScannedMessage}',
            icon: Icons.verified,
            color: AppColors.success,
          ),
        InfoRow(
          icon: Icons.person_outline,
          label: AppStrings.passenger,
          value: ticket.passengerName,
        ),
        InfoRow(icon: Icons.event, label: AppStrings.departureDate, value: ticket.departureLabel),
        InfoRow(icon: Icons.directions_bus, label: AppStrings.vehicle, value: ticket.vehicleLabel),
        InfoRow(icon: Icons.badge_outlined, label: AppStrings.driver, value: ticket.driverLabel),
        InfoRow(icon: Icons.business, label: AppStrings.organizer, value: ticket.companyName),
        InfoRow(icon: Icons.phone, label: AppStrings.companyPhone, value: ticket.companyPhoneLabel),
        InfoRow(
          icon: Icons.payments_outlined,
          label: AppStrings.pricePaid,
          value: Formatters.price(ticket.pricePaid),
        ),
        if (cancelledAtLabel != null)
          InfoRow(
            icon: Icons.cancel_outlined,
            label: AppStrings.cancelledAtPrefix,
            value: cancelledAtLabel,
          ),
        if (refundLabel != null)
          InfoRow(icon: Icons.undo, label: AppStrings.refundedPrefix, value: refundLabel),
        const SizedBox(height: AppSpacing.xl),
        if (canCancel) ...[
          OutlinedButton.icon(
            onPressed: isCancelling ? null : onCancel,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text(AppStrings.cancelTicket),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(ticket.cancelDeadlineLabel, style: textTheme.bodySmall, textAlign: TextAlign.center),
        ] else if (ticket.status.isUpcoming)
          Text(AppStrings.cancelWindowClosed, style: textTheme.bodySmall),
      ],
    );
  }
}
