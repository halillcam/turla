import 'package:equatable/equatable.dart';

/// İl. `id` plaka kodudur (1-81).
class City extends Equatable {
  const City({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
