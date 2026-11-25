import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/participant.dart';
import '../utils/guide_display.dart';

/// Katılımcı satırı: yeşil "Geldi · saat" / kırmızı "Gelmedi", arama düğmesi.
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
    final color = participant.hasArrived ? AppColors.arrived : AppColors.notArrived;

    return ListTile(
      contentPadding: AppPaddings.horizontalSm,
      onTap: participant.canCheckIn ? onCheckIn : null,
      leading: Icon(
        participant.hasArrived ? Icons.check_circle : Icons.radio_button_unchecked,
        color: color,
      ),
      title: Text(participant.passengerName),
      subtitle: Text(
        participant.statusLabel,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      trailing: participant.hasPhone
          ? IconButton(
              tooltip: AppStrings.callPassenger,
              onPressed: onCall,
              icon: const Icon(Icons.phone),
            )
          : null,
    );
  }
}
