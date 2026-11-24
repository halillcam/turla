import 'package:equatable/equatable.dart';

/// Tur firması (`companies` tablosu).
class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.isActive,
    this.cityId,
    this.phone,
  });

  final String id;
  final String name;
  final bool isActive;
  final int? cityId;
  final String? phone;

  @override
  List<Object?> get props => [id, name, isActive, cityId, phone];
}

/// Firma oluşturma / düzenleme formunun verisi.
class CompanyDraft extends Equatable {
  const CompanyDraft({required this.name, this.cityId, this.phone});

  final String name;
  final int? cityId;
  final String? phone;

  @override
  List<Object?> get props => [name, cityId, phone];
}
