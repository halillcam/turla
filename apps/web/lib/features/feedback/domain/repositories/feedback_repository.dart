import '../entities/feedback_item.dart';

/// Geri bildirimler. Firma admini kendi firmasınınkini okur ve yazar; super admin
/// hepsini okur ve durumunu değiştirir (RLS). Hatalar `PanelFailure` olarak fırlatılır.
abstract interface class FeedbackRepository {
  static const int pageSize = 50;

  /// [companyId] verilirse o firmanınkiler; verilmezse hepsi (super admin).
  Future<List<FeedbackItem>> list({String? companyId});

  Future<FeedbackItem> send({
    required String companyId,
    required String title,
    required String body,
  });

  Future<FeedbackItem> setStatus(FeedbackItem item, FeedbackStatus status);
}
