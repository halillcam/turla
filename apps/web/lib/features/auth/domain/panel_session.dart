import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

import '../../companies/domain/entities/company.dart';

/// Panele giriş neden reddedildi?
enum PanelDenial {
  /// Müşteri veya tur sorumlusu hesabı.
  roleNotAllowed,

  /// Şirket admininin firması pasif (veya bulunamadı).
  companyInactive,
}

/// Panel erişim kontrolü başarısız olduğunda fırlatılır. Fırlatılmadan önce
/// oturum kapatılmıştır.
class PanelAccessDenied implements Exception {
  const PanelAccessDenied(this.denial);

  final PanelDenial denial;

  @override
  String toString() => 'PanelAccessDenied($denial)';
}

/// Panele giriş yapmış kullanıcı. Şirket admini için [company] doludur.
class PanelSession extends Equatable {
  const PanelSession({required this.profile, this.company});

  final UserProfile profile;
  final Company? company;

  bool get isSuperAdmin => profile.role == UserRole.superAdmin;

  /// Şirket admininin firması; super admin için null.
  String? get ownCompanyId => isSuperAdmin ? null : profile.companyId;

  @override
  List<Object?> get props => [profile, company];
}
