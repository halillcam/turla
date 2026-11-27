import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/participant.dart';
import '../utils/guide_display.dart';

/// Katılımcı satırı: ad, renkli nokta + "Geldi · saat" / "Gelmedi", arama düğmesi.
/// Gelmemiş yolcuya dokununca (okutma açıksa) elle işaretleme sorulur.
class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    required this.participant,
    required this.onCheckIn,
    required this.onCall,
    super.key,
  });

  final Participant participant;

  /// Elle işaretleme kapalıysa null.
  final VoidCallback? onCheckIn;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final arrived = participant.hasArrived;
    final tone = arrived ? AppTone.success : AppTone.error;

    return InkWell(
      onTap: participant.canCheckIn ? onCheckIn : null,
      child: Padding(
        padding: AppPaddings.participantRow,
        child: Row(
          children: [
            Expanded(
              child: Text(participant.passengerName, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Container(
              width: AppSizes.statusDot,
              height: AppSizes.statusDot,
              decoration: BoxDecoration(color: tone.strong, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              participant.statusLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: tone.foreground,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
            if (participant.hasPhone)
              IconButton(
                tooltip: AppStrings.callPassenger,
                onPressed: onCall,
                icon: const Icon(Icons.call_outlined, size: AppSizes.iconMd),
                color: AppColors.primary,
              )
            else
              const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
