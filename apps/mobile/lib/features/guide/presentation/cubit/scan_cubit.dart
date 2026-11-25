import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/check_in_result.dart';
import '../../domain/entities/guide_failure.dart';
import '../../domain/repositories/guide_repository.dart';

part 'scan_state.dart';

/// QR okutma. Kamera aynı kodu saniyede birkaç kez yakalar; işlem sürerken,
/// sonuç ekrandayken ve aynı kod kısa süre içinde tekrar gelirse yok sayılır.
class ScanCubit extends Cubit<ScanState> {
  ScanCubit(this._repository, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now,
      super(const ScanState());

  final GuideRepository _repository;
  final DateTime Function() _now;
  String? _departureId;
  String? _lastCode;
  DateTime? _lastCodeAt;

  void start(String departureId) => _departureId = departureId;

  Future<void> submit(String rawCode) async {
    final departureId = _departureId;
    final code = rawCode.trim();
    if (departureId == null || code.isEmpty || state.status != ScanStatus.scanning) return;

    final now = _now();
    final lastAt = _lastCodeAt;
    if (code == _lastCode &&
        lastAt != null &&
        now.difference(lastAt) < AppDurations.scanRepeatGuard) {
      return;
    }
    _lastCode = code;
    _lastCodeAt = now;

    emit(state.copyWith(status: ScanStatus.processing));
    try {
      final result = await _repository.scanTicket(departureId: departureId, code: code);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ScanStatus.result,
          result: result,
          successCount: state.successCount + (result.isSuccess ? 1 : 0),
        ),
      );
    } on GuideFailure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(status: ScanStatus.failure, failure: failure.reason));
    }
  }

  /// "Sıradaki yolcu": kameraya dönülür. Aynı kod tekrar okunursa koruma süresi yine geçerli.
  void next() {
    _lastCodeAt = _now();
    emit(ScanState(successCount: state.successCount));
  }
}
