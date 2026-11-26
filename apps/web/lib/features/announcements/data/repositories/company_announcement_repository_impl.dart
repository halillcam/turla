import 'package:turla_core/turla_core.dart';

import '../../../../core/errors/panel_failure.dart';
import '../../../../core/errors/panel_guard.dart';
import '../../domain/entities/company_announcement.dart';
import '../../domain/repositories/company_announcement_repository.dart';

class CompanyAnnouncementRepositoryImpl implements CompanyAnnouncementRepository {
  const CompanyAnnouncementRepositoryImpl(this._client);

  static const String _table = 'company_announcements';
  static const String _columns = 'id, company_id, title, body, created_at, company:companies(name)';

  final SupabaseClient _client;

  @override
  Future<List<CompanyAnnouncement>> list({String? companyId}) => guardPanel(() async {
    var query = _client.from(_table).select(_columns);
    if (companyId != null) query = query.or('company_id.is.null,company_id.eq.$companyId');
    final rows = await query
        .order('created_at', ascending: false)
        .limit(CompanyAnnouncementRepository.pageSize);
    return rows.map(fromRow).toList();
  });

  @override
  Future<CompanyAnnouncement> create({
    required String title,
    required String body,
    String? companyId,
  }) => guardPanel(() async {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.length < CompanyAnnouncement.titleMinLength ||
        cleanTitle.length > CompanyAnnouncement.titleMaxLength ||
        cleanBody.isEmpty ||
        cleanBody.length > CompanyAnnouncement.bodyMaxLength) {
      throw const PanelFailure(PanelFailureReason.invalidInput);
    }
    final row = await _client
        .from(_table)
        .insert({'title': cleanTitle, 'body': cleanBody, 'company_id': companyId})
        .select(_columns)
        .single();
    return fromRow(row);
  });

  @override
  Future<void> delete(String id) => guardPanel(() => _client.from(_table).delete().eq('id', id));

  static CompanyAnnouncement fromRow(Map<String, dynamic> row) => CompanyAnnouncement(
    id: row['id'] as String,
    companyId: row['company_id'] as String?,
    companyName: (row['company'] as Map<String, dynamic>?)?['name'] as String?,
    title: row['title'] as String,
    body: row['body'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
