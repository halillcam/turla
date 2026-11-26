import '../entities/company_announcement.dart';

/// Firma duyuruları. Yazma ve silme sadece super admin (RLS); firma admini kendi
/// firmasına ve tüm firmalara yazılanları okur. Hatalar `PanelFailure` olarak fırlatılır.
abstract interface class CompanyAnnouncementRepository {
  static const int pageSize = 50;

  /// [companyId] verilirse o firmanın gördükleri (genel + firmaya özel); verilmezse hepsi.
  Future<List<CompanyAnnouncement>> list({String? companyId});

  Future<CompanyAnnouncement> create({
    required String title,
    required String body,
    String? companyId,
  });

  Future<void> delete(String id);
}
