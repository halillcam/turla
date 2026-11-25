import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import 'camera_error_view.dart';

/// Kamera önizlemesi ve okutma çerçevesi. Yakalanan ilk QR değeri [onCode]'a verilir;
/// tekrarları ScanCubit ayıklar.
class QrScannerView extends StatefulWidget {
  const QrScannerView({required this.onCode, required this.onEnterCode, super.key});

  final ValueChanged<String> onCode;
  final VoidCallback onEnterCode;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes.map((barcode) => barcode.rawValue).nonNulls.firstOrNull;
    if (value != null) widget.onCode(value);
  }

  @override
  Widget build(BuildContext context) {
    // Tarayıcı her zaman Stack'in ilk çocuğu kalır: yeri değişirse yeniden kurulur ve kamera
    // ikinci kez başlatılmaya çalışılır. Kamera açılamadıysa (izin yok / arıza) çerçeve ve ipucu
    // gösterilmez; hata görünümü kendi "Kodu elle gir" düğmesini taşır.
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => CameraErrorView(
            permissionDenied: error.errorCode == MobileScannerErrorCode.permissionDenied,
            onEnterCode: widget.onEnterCode,
          ),
        ),
        ValueListenableBuilder<MobileScannerState>(
          valueListenable: _controller,
          builder: (context, state, _) =>
              state.error == null ? _overlay(context) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _overlay(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: Center(
            child: Container(
              width: AppSizes.scanWindow,
              height: AppSizes.scanWindow,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.onPrimary, width: AppSizes.scanWindowBorder),
                borderRadius: AppRadius.lgAll,
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.xl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.scanHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonalIcon(
                onPressed: widget.onEnterCode,
                icon: const Icon(Icons.keyboard),
                label: const Text(AppStrings.enterCodeManually),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
