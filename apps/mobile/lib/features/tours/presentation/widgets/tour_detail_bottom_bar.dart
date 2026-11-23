import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';

/// Fiyat ve bilet butonu.
class TourDetailBottomBar extends StatelessWidget {
  const TourDetailBottomBar({
    required this.price,
    required this.isSignedIn,
    required this.isEnabled,
    required this.onPressed,
    super.key,
  });

  final double price;
  final bool isSignedIn;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: AppPaddings.allLg,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.pricePerPerson, style: textTheme.bodySmall),
                Text(
                  Formatters.price(price),
                  style: textTheme.headlineSmall?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: ElevatedButton(
                onPressed: isEnabled ? onPressed : null,
                child: Text(isSignedIn ? AppStrings.buyTicket : AppStrings.loginToBuy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
