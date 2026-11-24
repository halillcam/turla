import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

/// Panelden açılacak hesap. Firma admini e-posta ile, rehber ve dışarıdan
/// müşteri sunucunun ürettiği giriş kimliğiyle girer.
class NewAccount extends Equatable {
  const NewAccount({
    required this.role,
    required this.companyId,
    required this.fullName,
    required this.password,
    this.email,
    this.phone,
  });

  final UserRole role;
  final String companyId;
  final String fullName;
  final String password;

  /// Sadece firma admini için.
  final String? email;
  final String? phone;

  @override
  List<Object?> get props => [role, companyId, fullName, password, email, phone];
}

/// Açılan hesabın giriş bilgisi (şifre hariç).
class CreatedAccount extends Equatable {
  const CreatedAccount({required this.userId, required this.email, this.loginId});

  final String userId;
  final String email;
  final String? loginId;

  @override
  List<Object?> get props => [userId, email, loginId];
}
