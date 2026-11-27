import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../constants/strings.dart';

/// İnternet yokken cihazda kayıtlı verinin gösterildiğini belirtir.
class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({this.message = AppStrings.showingCachedTours, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ToneBanner(
      message: message,
      icon: Icons.wifi_off,
      tone: AppTone.warning,
      margin: AppMargins.cardList,
    );
  }
}
