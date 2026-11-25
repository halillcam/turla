part of 'scan_cubit.dart';

enum ScanStatus { scanning, processing, result, failure }

final class ScanState extends Equatable {
  const ScanState({
    this.status = ScanStatus.scanning,
    this.result,
    this.failure,
    this.successCount = 0,
  });

  final ScanStatus status;
  final CheckInResult? result;
  final GuideFailureReason? failure;

  /// Bu ekranda başarıyla okutulan yolcu sayısı (çıkınca liste yenilensin mi?).
  final int successCount;

  bool get isCameraActive => status == ScanStatus.scanning || status == ScanStatus.processing;

  ScanState copyWith({
    ScanStatus? status,
    CheckInResult? result,
    GuideFailureReason? failure,
    int? successCount,
  }) => ScanState(
    status: status ?? this.status,
    result: result ?? this.result,
    failure: failure,
    successCount: successCount ?? this.successCount,
  );

  @override
  List<Object?> get props => [status, result, failure, successCount];
}
