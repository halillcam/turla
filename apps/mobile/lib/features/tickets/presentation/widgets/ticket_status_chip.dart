import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Bilet durumu rozeti ("Ödendi", "İptal edildi" ...).
class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip({required this.status, super.key});

  final TicketStatus status;

  Color get _color => switch (status) {
    TicketStatus.reserved || TicketStatus.paid => AppColors.success,
    TicketStatus.checkedIn || TicketStatus.completed => AppColors.info,
    TicketStatus.cancelled || TicketStatus.noShow => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: AppFontSizes.caption, fontWeight: FontWeight.w600),
      ),
    );
  }
}
