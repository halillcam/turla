import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// İşlem sürerken yükleniyor göstergesi çıkaran ana buton.
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.loadingLabel,
    super.key,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  /// İşlem sürerken göstergenin yanında yazılacak metin ("Bilet hazırlanıyor...").
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final busyLabel = loadingLabel;
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: AppSizes.iconSm,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.progressStroke,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (busyLabel != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(child: Text(busyLabel, overflow: TextOverflow.ellipsis)),
                ],
              ],
            )
          : Text(label, textAlign: TextAlign.center),
    );
  }
}
