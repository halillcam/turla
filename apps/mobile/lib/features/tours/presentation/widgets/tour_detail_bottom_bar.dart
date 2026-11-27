import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';

/// Ekranın altına yapışık fiyat ve bilet düğmesi.
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppPaddings.bottomBar,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.pricePerPerson,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    Formatters.price(price),
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: ElevatedButton(
                  onPressed: isEnabled ? onPressed : null,
                  child: Text(
                    isSignedIn ? AppStrings.buyTicket : AppStrings.loginToBuy,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
