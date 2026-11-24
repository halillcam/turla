import '../entities/company.dart';

/// Firma işlemleri. Hatalar `PanelFailure` olarak fırlatılır.
///
/// Okuma: super admin hepsini, şirket admini sadece kendi (aktif) firmasını görür.
/// Yazma: sadece super admin (RLS).
abstract interface class CompanyRepository {
  Future<List<Company>> listCompanies();

  /// Görülemiyorsa (yok veya yetki dışı / pasif) null döner.
  Future<Company?> getCompany(String id);

  Future<Company> createCompany(CompanyDraft draft);

  Future<Company> updateCompany(String id, CompanyDraft draft);

  Future<Company> setCompanyActive(String id, {required bool isActive});
}
