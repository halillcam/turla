import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_failure.dart';

extension AppNotificationDisplay on AppNotification {
  /// "12 Ara 08:30"
  String get timeLabel => '${Formatters.shortDate(createdAt)} ${Formatters.time(createdAt)}';
}

extension NotificationFailureMessage on NotificationFailureReason {
  String get message => switch (this) {
    NotificationFailureReason.network => CoreStrings.networkError,
    NotificationFailureReason.notSignedIn => AppStrings.errorNotSignedIn,
    NotificationFailureReason.unknown => CoreStrings.unexpectedError,
  };
}
