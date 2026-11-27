import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/phone_launcher.dart';
import '../../../../core/widgets/detail_list.dart';
import '../../domain/entities/ticket.dart';
import '../utils/ticket_display.dart';
import 'ticket_perforation.dart';
import 'ticket_qr_ticket_section.dart';
import 'ticket_status_chip.dart';

/// Bilet detayı: tek bir basılı bilet kartı (başlık, QR ya da okutuldu bandı, kesim çizgisi,
/// bilgiler) ve altında aktif tur / iptal alanı.
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
    final companyPhone = ticket.companyPhone;

    return ListView(
      padding: AppPaddings.detailBody,
      children: [
        Card(
          borderOnForeground: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppPaddings.ticketStubTop,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(ticket.tourTitle, style: textTheme.titleLarge)),
                    const SizedBox(width: AppSpacing.md),
                    TicketStatusChip(status: ticket.status),
                  ],
                ),
              ),
              if (ticket.showsQr) TicketQrSection(qrToken: ticket.qrToken),
              if (ticket.showsScannedNotice)
                Padding(
                  padding: AppPaddings.ticketSection,
                  child: ToneBanner(
                    title: ticket.scannedLabel,
                    message: AppStrings.qrScannedMessage,
                    icon: Icons.verified,
                    tone: AppTone.success,
                  ),
                ),
              const TicketPerforation(),
              Padding(
                padding: AppPaddings.ticketStubTop,
                child: DetailList(
                  items: [
                    DetailItem(label: AppStrings.departureRowLabel, value: ticket.departureLabel),
                    DetailItem(label: AppStrings.passenger, value: ticket.passengerName),
                    DetailItem(
                      label: AppStrings.vehicle,
                      value: ticket.vehicleLabel,
                      isMono: ticket.busPlate != null,
                    ),
                    DetailItem(label: AppStrings.driver, value: ticket.driverLabel),
                    DetailItem(
                      label: AppStrings.organizer,
                      value: ticket.companyName,
                      actionLabel: AppStrings.callShort,
                      onAction: companyPhone == null || companyPhone.trim().isEmpty
                          ? null
                          : () => PhoneLauncher.call(companyPhone),
                    ),
                    DetailItem(
                      label: AppStrings.pricePaid,
                      value: Formatters.price(ticket.pricePaid),
                    ),
                    if (cancelledAtLabel != null)
                      DetailItem(label: AppStrings.cancelledAtPrefix, value: cancelledAtLabel),
                    if (refundLabel != null)
                      DetailItem(label: AppStrings.refundedPrefix, value: refundLabel),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (ticket.isActive) ...[
          ElevatedButton.icon(
            onPressed: onOpenActiveTour,
            icon: const Icon(Icons.tour_outlined, size: AppSizes.iconMd),
            label: const Text(AppStrings.activeTourButton),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (canCancel) ...[
          Text(ticket.cancelDeadlineLabel, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: isCancelling ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: AppSizes.borderWidth),
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
            ),
            child: const Text(AppStrings.cancelTicket),
          ),
        ] else if (ticket.status.isUpcoming)
          Text(AppStrings.cancelWindowClosed, style: textTheme.bodySmall),
      ],
    );
  }
}
