import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Bilet durumu rozeti ("Ödendi", "İptal edildi" ...).
class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip({required this.status, super.key});

  final TicketStatus status;

  AppTone get _tone => switch (status) {
    TicketStatus.reserved || TicketStatus.paid => AppTone.primary,
    TicketStatus.checkedIn => AppTone.success,
    TicketStatus.completed => AppTone.neutral,
    TicketStatus.cancelled || TicketStatus.noShow => AppTone.error,
  };

  @override
  Widget build(BuildContext context) => ToneBadge(label: status.label, tone: _tone);
}
