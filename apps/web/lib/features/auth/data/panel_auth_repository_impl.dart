import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turla_core/turla_core.dart';

import '../../../core/errors/panel_failure.dart';
import '../../companies/domain/entities/company.dart';
import '../../companies/domain/repositories/company_repository.dart';
import '../domain/panel_auth_repository.dart';
import '../domain/panel_session.dart';

class PanelAuthRepositoryImpl implements PanelAuthRepository {
  const PanelAuthRepositoryImpl({
    required AuthRepository authRepository,
    required CompanyRepository companyRepository,
    required this._authStates,
  }) : _auth = authRepository,
       _companies = companyRepository;

  final AuthRepository _auth;
  final CompanyRepository _companies;
  final Stream<AuthState> _authStates;

  @override
  Stream<void> get signedOut =>
      _authStates.where((state) => state.event == AuthChangeEvent.signedOut).map((_) {});

  @override
  Future<PanelSession?> currentSession() async {
    final profile = await _auth.currentProfile();
    if (profile == null) return null;
    return _authorize(profile);
  }

  @override
  Future<PanelSession> signIn({required String email, required String password}) async {
    final profile = await _auth.signInWithEmail(email: email, password: password);
    return _authorize(profile);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Rol ve firma kontrolü. Reddedilirse oturumu kapatıp [PanelAccessDenied] fırlatır.
  Future<PanelSession> _authorize(UserProfile profile) async {
    if (!profile.role.canUseWebPanel) {
      await _deny(PanelDenial.roleNotAllowed);
    }
    if (profile.role == UserRole.superAdmin) return PanelSession(profile: profile);

    final companyId = profile.companyId;
    if (companyId == null) await _deny(PanelDenial.companyInactive);

    // Pasif firmayı admin göremez (RLS); null gelirse firma pasif sayılır.
    final Company? company;
    try {
      company = await _companies.getCompany(companyId);
    } on PanelFailure catch (failure) {
      throw AuthFailure(
        failure.reason == PanelFailureReason.network
            ? AuthFailureReason.network
            : AuthFailureReason.unknown,
        failure,
      );
    }
    if (company == null || !company.isActive) await _deny(PanelDenial.companyInactive);
    return PanelSession(profile: profile, company: company);
  }

  Future<Never> _deny(PanelDenial denial) async {
    try {
      await _auth.signOut();
    } on AuthFailure {
      // Ağ hatası olsa da yerel oturum kapanır.
    }
    throw PanelAccessDenied(denial);
  }
}
