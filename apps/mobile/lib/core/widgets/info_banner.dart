import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Tonlu bilgi bandı (onay bekliyor, reddedildi, tamamlandı ...). Altında liste boşluğu bırakır.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.message,
    this.icon = Icons.info_outline,
    this.tone = AppTone.primary,
    this.title,
    super.key,
  });

  final String message;
  final IconData icon;
  final AppTone tone;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return ToneBanner(
      message: message,
      icon: icon,
      tone: tone,
      title: title,
      margin: AppMargins.cardList,
    );
  }
}
