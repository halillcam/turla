import 'package:equatable/equatable.dart';

enum CompletionStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const CompletionStatus(this.value);

  final String value;

  static CompletionStatus fromValue(String value) => CompletionStatus.values.firstWhere(
    (status) => status.value == value,
    orElse: () => CompletionStatus.pending,
  );
}

/// Rehberin "turu bitir" talebi. Onay sadece ilgili tarihi kapatır.
class CompletionRequest extends Equatable {
  const CompletionRequest({
    required this.id,
    required this.departureId,
    required this.tourTitle,
    required this.departureAt,
    required this.guideName,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String departureId;
  final String tourTitle;
  final DateTime departureAt;
  final String guideName;
  final CompletionStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  bool get isPending => status == CompletionStatus.pending;

  @override
  List<Object?> get props => [
    id,
    departureId,
    tourTitle,
    departureAt,
    guideName,
    status,
    createdAt,
    reviewedAt,
  ];
}
