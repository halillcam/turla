import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/widgets/info_banner.dart';
import '../../domain/entities/guide_departure.dart';
import '../utils/guide_display.dart';

/// Onay bekliyor / reddedildi / tamamlandı bandı. Gerekmiyorsa boş.
class DepartureStatusBanner extends StatelessWidget {
  const DepartureStatusBanner({required this.departure, super.key});

  final GuideDeparture departure;

  @override
  Widget build(BuildContext context) {
    final message = departure.statusBanner;
    if (message == null) return const SizedBox.shrink();
    final (icon, color) = departure.wasRejected
        ? (Icons.report_outlined, AppColors.error)
        : departure.isAwaitingApproval
        ? (Icons.hourglass_top, AppColors.warning)
        : (Icons.check_circle_outline, AppColors.info);
    return InfoBanner(message: message, icon: icon, color: color);
  }
}
