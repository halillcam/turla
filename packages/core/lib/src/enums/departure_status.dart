import '../constants/core_strings.dart';

/// Veritabanındaki `departure_status` tipinin karşılığı.
enum DepartureStatus {
  scheduled('scheduled', CoreStrings.departureScheduled),
  finishRequested('finish_requested', CoreStrings.departureFinishRequested),
  completed('completed', CoreStrings.departureCompleted),
  cancelled('cancelled', CoreStrings.departureCancelled);

  const DepartureStatus(this.value, this.label);

  final String value;
  final String label;

  static DepartureStatus fromValue(String value) => DepartureStatus.values.firstWhere(
    (status) => status.value == value,
    orElse: () => DepartureStatus.scheduled,
  );
}
