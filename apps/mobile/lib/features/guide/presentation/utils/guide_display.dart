import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/check_in_result.dart';
import '../../domain/entities/guide_departure.dart';
import '../../domain/entities/guide_failure.dart';
import '../../domain/entities/participant.dart';

/// Kalkışın ekranda gösterilecek metinleri.
extension GuideDepartureDisplay on GuideDeparture {
  /// "12 Aralık 2026, Cumartesi · 08:30"
  String get departureLabel => '${Formatters.date(departureAt)} · ${Formatters.time(departureAt)}';

  /// "46 ABC 101 · Mehmet Kaya" (boş olanlar atlanır; ikisi de boşsa null).
  String? get vehicleLabel {
    final parts = [
      busPlate,
      driverName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// "Şoför Ali Demir"; şoför yoksa null.
  String? get driverLine {
    final name = driverName?.trim() ?? '';
    return name.isEmpty ? null : '${AppStrings.driver} $name';
  }

  bool get hasDriverPhone => driverPhone?.trim().isNotEmpty ?? false;

  /// Sohbet ve duyurular tur açıkken görünür; tur bitince sohbet gizlenir.
  bool get showsLiveTools => isActive || isAwaitingApproval;

  /// Durum bandı metni; bant gerekmiyorsa null.
  String? get statusBanner {
    if (isAwaitingApproval) return AppStrings.awaitingApprovalBanner;
    if (wasRejected) return AppStrings.completionRejectedBanner;
    if (isCompleted) return AppStrings.departureCompletedBanner;
    return null;
  }
}

/// Katılımcının durum metni.
extension ParticipantDisplay on Participant {
  /// "Geldi · 08:12", "Geldi · 08:12 · elle" veya "Gelmedi".
  String get statusLabel {
    if (!hasArrived) return AppStrings.notArrived;
    final at = checkedInAt;
    return [
      AppStrings.arrivedAtPrefix,
      if (at != null) Formatters.time(at),
      if (checkInMethod == CheckInMethod.manual) AppStrings.manualSuffix,
    ].join(' · ');
  }
}

/// Okutma sonucunun başlığı ve açıklaması.
extension CheckInResultDisplay on CheckInResult {
  String get title => switch (code) {
    CheckInCode.ok => AppStrings.scanOkTitle,
    CheckInCode.alreadyUsed => AppStrings.scanAlreadyUsedTitle,
    CheckInCode.wrongDeparture => AppStrings.scanWrongDepartureTitle,
    CheckInCode.notFound => AppStrings.scanNotFoundTitle,
    CheckInCode.cancelled => AppStrings.scanCancelledTitle,
    CheckInCode.notPaid => AppStrings.scanNotPaidTitle,
  };

  String get message {
    final at = scannedAt;
    return switch (code) {
      CheckInCode.ok => AppStrings.scanOkMessage,
      CheckInCode.alreadyUsed =>
        at == null
            ? AppStrings.scanAlreadyUsedMessage
            : '${AppStrings.scanAlreadyUsedMessage} (${Formatters.time(at)})',
      CheckInCode.wrongDeparture => AppStrings.scanWrongDepartureMessage,
      CheckInCode.notFound => AppStrings.scanNotFoundMessage,
      CheckInCode.cancelled => AppStrings.scanCancelledMessage,
      CheckInCode.notPaid => AppStrings.scanNotPaidMessage,
    };
  }
}

/// Rehber hata türünü kullanıcıya gösterilecek metne çevirir.
extension GuideFailureMessage on GuideFailureReason {
  String get message => switch (this) {
    GuideFailureReason.network => CoreStrings.networkError,
    GuideFailureReason.notSignedIn => AppStrings.errorNotSignedIn,
    GuideFailureReason.notAllowed => AppStrings.errorGuideNotAllowed,
    GuideFailureReason.departureNotFound => AppStrings.departureNotFound,
    GuideFailureReason.departureNotActive => AppStrings.errorDepartureNotActive,
    GuideFailureReason.departureNotStarted => AppStrings.errorDepartureNotStarted,
    GuideFailureReason.ticketNotFound => AppStrings.errorTicketNotFound,
    GuideFailureReason.unknown => CoreStrings.unexpectedError,
  };
}
