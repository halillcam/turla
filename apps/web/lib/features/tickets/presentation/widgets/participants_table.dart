import 'package:flutter/material.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/panel_page.dart';
import '../../domain/entities/participant_ticket.dart';
import '../utils/participant_display.dart';

/// Tarihin bilet tablosu: yolcu, durum, kaynak, ödenen, alış zamanı, iptal.
class ParticipantsTable extends StatelessWidget {
  const ParticipantsTable({
    required this.tickets,
    required this.canCancel,
    required this.onCancel,
    super.key,
  });

  final List<ParticipantTicket> tickets;

  /// İşlem sürerken veya tarih kapandıysa iptal düğmeleri kapalı.
  final bool canCancel;
  final ValueChanged<ParticipantTicket> onCancel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PanelTableCard(
        child: DataTable(
          columns: const [
            DataColumn(label: Text(AppStrings.passengerColumn)),
            DataColumn(label: Text(AppStrings.phoneColumn)),
            DataColumn(label: Text(AppStrings.statusColumn)),
            DataColumn(label: Text(AppStrings.ticketSourceColumn)),
            DataColumn(label: Text(AppStrings.pricePaidColumn)),
            DataColumn(label: Text(AppStrings.purchasedAtColumn)),
            DataColumn(label: SizedBox.shrink()),
          ],
          rows: [
            for (final ticket in tickets)
              DataRow(
                cells: [
                  DataCell(Text(ticket.passengerName)),
                  DataCell(SelectableText(ticket.phoneLabel)),
                  DataCell(Text(ticket.statusLabel)),
                  DataCell(Text(ticket.sourceLabel)),
                  DataCell(Text(ticket.priceLabel)),
                  DataCell(Text(ticket.purchasedAtLabel)),
                  DataCell(
                    ticket.isCancellable
                        ? IconButton(
                            onPressed: canCancel ? () => onCancel(ticket) : null,
                            icon: const Icon(Icons.cancel_outlined),
                            tooltip: AppStrings.cancelTicket,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
