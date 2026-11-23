import 'package:equatable/equatable.dart';

class TourProgramDay extends Equatable {
  const TourProgramDay({required this.dayNo, required this.title, required this.activities});

  final int dayNo;
  final String title;
  final List<String> activities;

  @override
  List<Object?> get props => [dayNo, title, activities];
}
