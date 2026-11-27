import 'package:flutter/material.dart';

import '../constants/paddings.dart';
import '../constants/radius.dart';
import '../constants/sizes.dart';
import '../theme/app_text_styles.dart';
import 'app_tone.dart';

/// Hap biçimli durum rozeti ("4 koltuk kaldı", "Geldi", "Tamamlandı").
class ToneBadge extends StatelessWidget {
  const ToneBadge({required this.label, this.tone = AppTone.neutral, this.icon, super.key});

  final String label;
  final AppTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.labelSmall.copyWith(color: tone.foreground);
    return DecoratedBox(
      decoration: BoxDecoration(color: tone.background, borderRadius: AppRadius.pillAll),
      child: Padding(
        padding: AppPaddings.badge,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizes.iconXs, color: tone.foreground),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(label, style: style, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
