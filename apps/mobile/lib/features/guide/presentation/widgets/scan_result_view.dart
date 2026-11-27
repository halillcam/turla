import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/status_circle.dart';
import '../../domain/entities/check_in_result.dart';
import '../utils/guide_display.dart';

/// Okutma sonucu kartı: tonlu daire içinde ikon, başlık, yolcu adı, açıklama ve
/// "Sıradaki yolcu". Yeşil (katıldı), turuncu (daha önce okutulmuş), kırmızı (sorun).
class ScanResultView extends StatelessWidget {
  const ScanResultView({
    required this.title,
    required this.message,
    required this.tone,
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
    final (tone, icon) = switch (result.code) {
      CheckInCode.ok => (AppTone.success, Icons.check_circle),
      CheckInCode.alreadyUsed => (AppTone.warning, Icons.history),
      CheckInCode.wrongDeparture => (AppTone.error, Icons.event_busy),
      CheckInCode.notFound => (AppTone.error, Icons.search_off),
      _ => (AppTone.error, Icons.error_outline),
    };
    return ScanResultView(
      title: result.title,
      message: result.message,
      passengerName: result.passengerName,
      tone: tone,
      icon: icon,
      onNext: onNext,
      onBackToList: onBackToList,
    );
  }

  final String title;
  final String message;
  final String? passengerName;
  final AppTone tone;
  final IconData icon;
  final VoidCallback onNext;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = passengerName;

    return Center(
      child: SingleChildScrollView(
        padding: AppPaddings.screen,
        child: Card(
          child: Padding(
            padding: AppPaddings.allXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: StatusCircle(icon: icon, tone: tone),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(color: tone.foreground),
                  textAlign: TextAlign.center,
                ),
                if (name != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(name, style: textTheme.headlineSmall, textAlign: TextAlign.center),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.qr_code_scanner, size: AppSizes.iconMd),
                  label: const Text(AppStrings.nextPassenger),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(onPressed: onBackToList, child: const Text(AppStrings.backToList)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
