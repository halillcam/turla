import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import 'ticket_perforation.dart';
import 'ticket_qr_ticket_section.dart';

/// Basılı bilet görünümünde QR kartı: üstte tur ve tarih, delikli kesim çizgisi, altta QR ve kod.
class TicketQrCard extends StatelessWidget {
  const TicketQrCard({required this.qrToken, required this.title, this.subtitle, super.key});

  final String qrToken;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitleText = subtitle;
    return Card(
      // Kenarlık arkada çizilir ki çentikler kenarlığın üstünü örtsün.
      borderOnForeground: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppPaddings.ticketStubTop,
            child: Column(
              children: [
                Text(title, style: textTheme.titleLarge, textAlign: TextAlign.center),
                if (subtitleText != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitleText,
                    style: textTheme.bodySmall?.copyWith(
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const TicketPerforation(),
          const SizedBox(height: AppSpacing.lg),
          TicketQrSection(qrToken: qrToken),
        ],
      ),
    );
  }
}
