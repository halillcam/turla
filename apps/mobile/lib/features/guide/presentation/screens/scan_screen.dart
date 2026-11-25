import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../cubit/scan_cubit.dart';
import '../utils/guide_display.dart';
import '../widgets/manual_code_dialog.dart';
import '../widgets/qr_scanner_view.dart';
import '../widgets/scan_result_view.dart';

/// Kamera görünümü. Testte kamera yerine sahte görünüm verilir.
typedef ScannerBuilder = Widget Function(ValueChanged<String> onCode, VoidCallback onEnterCode);

/// QR okutma: kamera → sonuç → "Sıradaki yolcu". Kamera açılmazsa kod elle girilir.
class ScanScreen extends StatelessWidget {
  const ScanScreen({required this.departureId, this.scannerBuilder, super.key});

  final String departureId;

  @visibleForTesting
  final ScannerBuilder? scannerBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScanCubit>()..start(departureId),
      child: _ScanView(scannerBuilder: scannerBuilder),
    );
  }
}

class _ScanView extends StatelessWidget {
  const _ScanView({required this.scannerBuilder});

  final ScannerBuilder? scannerBuilder;

  Future<void> _enterCode(BuildContext context) async {
    final cubit = context.read<ScanCubit>();
    final code = await ManualCodeDialog.show(context);
    if (code != null) await cubit.submit(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.scanTitle)),
      body: SafeArea(
        child: BlocBuilder<ScanCubit, ScanState>(
          builder: (context, state) {
            final cubit = context.read<ScanCubit>();
            final result = state.result;
            final failure = state.failure;

            if (state.status == ScanStatus.result && result != null) {
              return ScanResultView.fromResult(
                result: result,
                onNext: cubit.next,
                onBackToList: () => context.pop(),
              );
            }
            if (state.status == ScanStatus.failure && failure != null) {
              return ScanResultView(
                title: AppStrings.scanFailureTitle,
                message: failure.message,
                color: AppColors.notArrived,
                icon: Icons.wifi_off,
                onNext: cubit.next,
                onBackToList: () => context.pop(),
              );
            }

            final builder = scannerBuilder;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (builder != null)
                  builder(cubit.submit, () => _enterCode(context))
                else
                  QrScannerView(onCode: cubit.submit, onEnterCode: () => _enterCode(context)),
                if (state.status == ScanStatus.processing)
                  const ColoredBox(
                    color: AppColors.scrim,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
