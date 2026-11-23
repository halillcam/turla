import 'package:equatable/equatable.dart';

import '../../../../enums/user_role.dart';

/// Giriş yapmış kullanıcının profili (`profiles` tablosu + oturum e-postası).
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.companyId,
    this.phone,
    this.selectedCityId,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final String? companyId;
  final String? phone;
  final int? selectedCityId;

  UserProfile copyWith({int? selectedCityId}) => UserProfile(
    id: id,
    email: email,
    fullName: fullName,
    role: role,
    isActive: isActive,
    companyId: companyId,
    phone: phone,
    selectedCityId: selectedCityId ?? this.selectedCityId,
  );

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    role,
    isActive,
    companyId,
    phone,
    selectedCityId,
  ];
}
