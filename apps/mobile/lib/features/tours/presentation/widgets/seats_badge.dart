import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// "5 koltuk kaldı" / "Dolu" rozeti. Az koltuk kaldıysa uyarı tonunda.
class SeatsBadge extends StatelessWidget {
  const SeatsBadge({required this.seatsLeft, super.key});

  /// Bu sayı ve altı "az kaldı" sayılır (sadece görünüm).
  static const int fewSeatsThreshold = 5;

  final int seatsLeft;

  @override
  Widget build(BuildContext context) {
    final isSoldOut = seatsLeft <= 0;
    final tone = isSoldOut
        ? AppTone.error
        : seatsLeft <= fewSeatsThreshold
        ? AppTone.warning
        : AppTone.success;
    return ToneBadge(
      label: isSoldOut ? AppStrings.soldOut : '$seatsLeft ${AppStrings.seatsLeftSuffix}',
      tone: tone,
    );
  }
}
