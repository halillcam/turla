import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/active_tour.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/live_tour_failure.dart';

extension ActiveTourDisplay on ActiveTour {
  /// "12 Aralık 2026, Cumartesi · 08:30"
  String get departureLabel => '${Formatters.date(departureAt)} · ${Formatters.time(departureAt)}';

  String get guideLabel => _orFallback(guideName, AppStrings.guideNotAssigned);

  /// "46 ABC 101 · Mehmet Kaya" ya da "Belirtilmedi".
  String get vehicleLabel {
    final parts = [busPlate, driverName].whereType<String>().where((p) => p.trim().isNotEmpty);
    return parts.isEmpty ? AppStrings.notSpecified : parts.join(' · ');
  }

  bool get hasDriverPhone => (driverPhone ?? '').trim().isNotEmpty;

  String get companyPhoneLabel => _orFallback(companyPhone, AppStrings.notSpecified);

  /// Sohbete yazılabilir mi; değilse ekran salt okunur açılır.
  bool get canWriteChat => chatOpen;
}

extension ChatMessageDisplay on ChatMessage {
  /// Gönderenin rol etiketi (yolcuda yok).
  String? get roleTag => switch (senderRole) {
    UserRole.guide => AppStrings.senderGuideTag,
    UserRole.admin || UserRole.superAdmin => AppStrings.senderCompanyTag,
    UserRole.customer => null,
  };

  /// "Ahmet Yılmaz · Tur sorumlusu"
  String senderLabel(String? currentUserId) {
    final name = isMine(currentUserId) ? AppStrings.you : senderName;
    final tag = roleTag;
    return tag == null ? name : '$name · $tag';
  }

  /// Bugünse "08:12", değilse "12 Ara 08:12".
  String timeLabel(DateTime now) {
    final local = createdAt.toLocal();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    return sameDay
        ? Formatters.time(local)
        : '${Formatters.shortDate(local)} ${Formatters.time(local)}';
  }
}

extension AnnouncementDisplay on Announcement {
  String get timeLabel => '${Formatters.shortDate(createdAt)} ${Formatters.time(createdAt)}';
}

/// "Sadece QR kodu okutulmuş 12 yolcuya gider."
String announcementRecipientsLabel(int count) =>
    '${AppStrings.announcementRecipientsPrefix} $count ${AppStrings.announcementRecipientsSuffix}';

extension LiveTourFailureMessage on LiveTourFailureReason {
  String get message => switch (this) {
    LiveTourFailureReason.network => CoreStrings.networkError,
    LiveTourFailureReason.notSignedIn => AppStrings.errorNotSignedIn,
    LiveTourFailureReason.notAllowed => AppStrings.errorChatNotAllowed,
    LiveTourFailureReason.departureNotActive => AppStrings.activeTourClosed,
    LiveTourFailureReason.rateLimited => AppStrings.errorChatRateLimited,
    LiveTourFailureReason.messageTooLong => AppStrings.errorMessageTooLong,
    LiveTourFailureReason.unknown => CoreStrings.unexpectedError,
  };
}

String _orFallback(String? value, String fallback) =>
    (value == null || value.trim().isEmpty) ? fallback : value;
