import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/check_in_result.dart';
import '../utils/guide_display.dart';

/// Okutma sonucu: yeşil (katıldı) veya kırmızı/turuncu (sorun), "Sıradaki yolcu".
class ScanResultView extends StatelessWidget {
  const ScanResultView({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.onNext,
    required this.onBackToList,
    this.passengerName,
    super.key,
  });

  factory ScanResultView.fromResult({
    required CheckInResult result,
    required VoidCallback onNext,
    required VoidCallback onBackToList,
  }) {
    final (color, icon) = switch (result.code) {
      CheckInCode.ok => (AppColors.arrived, Icons.check_circle),
      CheckInCode.alreadyUsed => (AppColors.warning, Icons.history),
      _ => (AppColors.notArrived, Icons.error),
    };
    return ScanResultView(
      title: result.title,
      message: result.message,
      passengerName: result.passengerName,
      color: color,
      icon: icon,
      onNext: onNext,
      onBackToList: onBackToList,
    );
  }

  final String title;
  final String message;
  final String? passengerName;
  final Color color;
  final IconData icon;
  final VoidCallback onNext;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = passengerName;

    return Padding(
      padding: AppPaddings.allXl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: AppSizes.statusIconLarge, color: color),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          if (name != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(name, style: textTheme.titleLarge, textAlign: TextAlign.center),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text(AppStrings.nextPassenger),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onBackToList, child: const Text(AppStrings.backToList)),
        ],
      ),
    );
  }
}
