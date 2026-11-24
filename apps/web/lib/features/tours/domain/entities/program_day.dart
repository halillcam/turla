import 'package:equatable/equatable.dart';

/// Tur programının bir günü. Gün numarası listedeki sırasıdır.
class ProgramDay extends Equatable {
  const ProgramDay({this.title = '', this.activities = const []});

  final String title;
  final List<String> activities;

  ProgramDay copyWith({String? title, List<String>? activities}) =>
      ProgramDay(title: title ?? this.title, activities: activities ?? this.activities);

  @override
  List<Object?> get props => [title, activities];
}
