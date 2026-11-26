import '../../../../core/constants/strings.dart';
import '../../domain/entities/feedback_item.dart';

extension FeedbackStatusDisplay on FeedbackStatus {
  String get label => switch (this) {
    FeedbackStatus.open => AppStrings.feedbackOpen,
    FeedbackStatus.inProgress => AppStrings.feedbackInProgress,
    FeedbackStatus.resolved => AppStrings.feedbackResolved,
  };
}
