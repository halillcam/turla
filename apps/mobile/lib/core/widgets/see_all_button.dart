import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../constants/strings.dart';

/// Bölüm başlığının sağındaki "Tümünü gör ›" düğmesi.
class SeeAllButton extends StatelessWidget {
  const SeeAllButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(textStyle: AppTextStyles.labelMedium),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.seeAll),
          Icon(Icons.chevron_right, size: AppSizes.iconBanner),
        ],
      ),
    );
  }
}
