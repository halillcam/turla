import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// MVP'deki demo ödeme notu: kart alanı yok, gerçek tahsilat yapılmaz.
class DemoPaymentCard extends StatelessWidget {
  const DemoPaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToneBanner(
      title: AppStrings.demoPaymentTitle,
      message: AppStrings.demoPaymentNote,
      tone: AppTone.warning,
    );
  }
}
