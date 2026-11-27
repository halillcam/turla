import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/departure.dart';

extension DepartureCancellationDisplay on DepartureCancellation {
  /// "Tarih iptal edildi. İptal edilen bilet: 3 · İade: ₺5.550"
  String get summary =>
      '${AppStrings.departureCancelledPrefix} $cancelledTickets · '
      '${AppStrings.refundLabel}: ${Formatters.price(refundedTotal)}';
}

extension DepartureStatusDisplay on DepartureStatus {
  /// Tablodaki durum rozetinin tonu.
  AppTone get tone => switch (this) {
    DepartureStatus.scheduled => AppTone.primary,
    DepartureStatus.finishRequested => AppTone.warning,
    DepartureStatus.completed => AppTone.success,
    DepartureStatus.cancelled => AppTone.error,
  };
}
