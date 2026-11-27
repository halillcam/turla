import 'package:equatable/equatable.dart';

/// Veritabanındaki `feedback_status` tipinin karşılığı.
enum FeedbackStatus {
  open('open'),
  inProgress('in_progress'),
  resolved('resolved');

  const FeedbackStatus(this.value);

  final String value;

  static FeedbackStatus fromValue(String value) =>
      FeedbackStatus.values.firstWhere((s) => s.value == value, orElse: () => FeedbackStatus.open);
}

/// Firma admininin super admin'e geri bildirimi.
class FeedbackItem extends Equatable {
  const FeedbackItem({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.authorName,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
  });

  static const int titleMaxLength = 160;
  static const int bodyMaxLength = 4000;

  final String id;
  final String companyId;
  final String companyName;
  final String authorName;
  final String title;
  final String body;
  final FeedbackStatus status;
  final DateTime createdAt;

  FeedbackItem withStatus(FeedbackStatus status) => FeedbackItem(
    id: id,
    companyId: companyId,
    companyName: companyName,
    authorName: authorName,
    title: title,
    body: body,
    status: status,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    companyId,
    companyName,
    authorName,
    title,
    body,
    status,
    createdAt,
  ];
}
