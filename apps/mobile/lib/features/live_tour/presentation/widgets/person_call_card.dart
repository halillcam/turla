import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// Kart: küçük etiket + ad (tur sorumlusu, araç/şoför) ve telefon varsa sağda "Ara" düğmesi.
/// Düğme telefonun arama uygulamasını açar.
class PersonCallCard extends StatelessWidget {
  const PersonCallCard({
    required this.label,
    required this.name,
    required this.callTooltip,
    this.onCall,
    this.isMono = false,
    this.detail,
    super.key,
  });

  final String label;
  final String name;
  final String callTooltip;

  /// Null ise (telefon yok) düğme gösterilmez.
  final VoidCallback? onCall;

  /// Plaka gibi değerler için eş aralıklı yazı.
  final bool isMono;

  /// Adın yanında normal yazıyla ek bilgi (plakanın yanında şoför).
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final call = onCall;
    return Card(
      child: Padding(
        padding: AppPaddings.card,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text.rich(
                    TextSpan(
                      text: name,
                      style: isMono ? AppTextStyles.mono : textTheme.titleMedium,
                      children: [
                        if (detail != null) TextSpan(text: detail, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (call != null)
              Tooltip(
                message: callTooltip,
                child: FilledButton.icon(
                  onPressed: call,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryTint,
                    foregroundColor: AppColors.primary,
                    textStyle: AppTextStyles.labelMedium,
                  ),
                  icon: const Icon(Icons.call, size: AppSizes.iconBanner),
                  label: const Text(AppStrings.callShort),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
