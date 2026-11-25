import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// İşlem sürerken yükleniyor göstergesi çıkaran ana buton.
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox.square(
              dimension: AppSizes.iconMd,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
            )
          : Text(label),
    );
  }
}
