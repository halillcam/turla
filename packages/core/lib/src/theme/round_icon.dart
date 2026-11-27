import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';

/// Açık yüzeyli, ince kenarlıklı daire içinde ikon (geri, çıkış gibi üst çubuk düğmeleri).
class RoundIcon extends StatelessWidget {
  const RoundIcon({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.roundBackButton,
      height: AppSizes.roundBackButton,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
      ),
      child: Icon(icon, size: AppSizes.iconMd, color: AppColors.textPrimary),
    );
  }
}
