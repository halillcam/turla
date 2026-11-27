import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Tonlu daire içinde durum ikonu (başarı, hata, uyarı). Sonuç ekranlarının başında durur.
class StatusCircle extends StatelessWidget {
  const StatusCircle({
    required this.icon,
    this.tone = AppTone.success,
    this.size = AppSizes.statusCircle,
    super.key,
  });

  final IconData icon;
  final AppTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone.background, shape: BoxShape.circle),
      child: Icon(icon, size: size * AppSizes.statusCircleIconRatio, color: tone.foreground),
    );
  }
}
