import 'package:turla_core/turla_core.dart';

import '../../../../core/errors/panel_failure.dart';
import '../../../../core/errors/panel_guard.dart';
import '../../domain/entities/feedback_item.dart';
import '../../domain/repositories/feedback_repository.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  const FeedbackRepositoryImpl(this._client);

  static const String _table = 'feedbacks';
  static const String _columns =
      'id, company_id, title, body, status, created_at, company:companies(name), '
      'author:profiles!feedbacks_created_by_fkey(full_name)';
  static const int _titleMinLength = 3;

  final SupabaseClient _client;

  @override
  Future<List<FeedbackItem>> list({String? companyId}) => guardPanel(() async {
    var query = _client.from(_table).select(_columns);
    if (companyId != null) query = query.eq('company_id', companyId);
    final rows = await query.order('created_at', ascending: false).limit(FeedbackRepository.pageSize);
    return rows.map(fromRow).toList();
  });

  @override
  Future<FeedbackItem> send({
    required String companyId,
    required String title,
    required String body,
  }) => guardPanel(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const PanelFailure(PanelFailureReason.notAllowed);
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.length < _titleMinLength ||
        cleanTitle.length > FeedbackItem.titleMaxLength ||
        cleanBody.isEmpty ||
        cleanBody.length > FeedbackItem.bodyMaxLength) {
      throw const PanelFailure(PanelFailureReason.invalidInput);
    }
    final row = await _client
        .from(_table)
        .insert({
          'company_id': companyId,
          'created_by': userId,
          'title': cleanTitle,
          'body': cleanBody,
        })
        .select(_columns)
        .single();
    return fromRow(row);
  });

  @override
  Future<FeedbackItem> setStatus(FeedbackItem item, FeedbackStatus status) =>
      guardPanel(() async {
        await _client.from(_table).update({'status': status.value}).eq('id', item.id);
        return item.withStatus(status);
      });

  static FeedbackItem fromRow(Map<String, dynamic> row) => FeedbackItem(
    id: row['id'] as String,
    companyId: row['company_id'] as String,
    companyName: ((row['company'] as Map<String, dynamic>?)?['name'] as String?) ?? '',
    authorName: ((row['author'] as Map<String, dynamic>?)?['full_name'] as String?) ?? '',
    title: row['title'] as String,
    body: row['body'] as String,
    status: FeedbackStatus.fromValue(row['status'] as String),
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
