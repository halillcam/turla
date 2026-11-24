import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

/// Firmaya bağlı hesap: firma admini, tur sorumlusu veya dışarıdan eklenen müşteri.
class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.loginId,
    this.phone,
  });

  final String id;
  final String fullName;
  final UserRole role;
  final bool isActive;

  /// Rehber ve dışarıdan müşteri için giriş kimliği (ör. REH-1234).
  final String? loginId;
  final String? phone;

  StaffMember copyWith({bool? isActive}) => StaffMember(
    id: id,
    fullName: fullName,
    role: role,
    isActive: isActive ?? this.isActive,
    loginId: loginId,
    phone: phone,
  );

  @override
  List<Object?> get props => [id, fullName, role, isActive, loginId, phone];
}
