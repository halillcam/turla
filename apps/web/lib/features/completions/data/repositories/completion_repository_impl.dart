import 'package:turla_core/turla_core.dart';

import '../../../../core/errors/panel_guard.dart';
import '../../domain/entities/completion_request.dart';
import '../../domain/repositories/completion_repository.dart';

class CompletionRepositoryImpl implements CompletionRepository {
  const CompletionRepositoryImpl(this._client);

  static const int defaultLimit = 50;

  // completion_requests → profiles iki kez bağlı (guide_id, reviewed_by);
  // hangi ilişkinin kullanılacağı yabancı anahtar adıyla belirtilir.
  static const String _columns =
      'id, departure_id, status, created_at, reviewed_at, '
      'guide:profiles!completion_requests_guide_id_fkey(full_name), '
      'departure:tour_departures!completion_requests_departure_id_fkey(departure_at, tour:tours(title))';

  final SupabaseClient _client;

  @override
  Future<List<CompletionRequest>> listRequests(String companyId, {int limit = defaultLimit}) =>
      guardPanel(() async {
        final rows = await _client
            .from('completion_requests')
            .select(_columns)
            .eq('company_id', companyId)
            .order('created_at', ascending: false)
            .limit(limit);
        return rows.map(fromRow).toList();
      });

  @override
  Future<CompletionRequest> review(CompletionRequest request, {required bool approve}) =>
      guardPanel(() async {
        final row = await _client.rpc<Map<String, dynamic>>(
          'review_departure_completion',
          params: {'p_request_id': request.id, 'p_approve': approve},
        );
        return CompletionRequest(
          id: request.id,
          departureId: request.departureId,
          tourTitle: request.tourTitle,
          departureAt: request.departureAt,
          guideName: request.guideName,
          status: CompletionStatus.fromValue(row['status'] as String),
          createdAt: request.createdAt,
          reviewedAt: DateTime.tryParse((row['reviewed_at'] as String?) ?? ''),
        );
      });

  static CompletionRequest fromRow(Map<String, dynamic> row) {
    final departure = row['departure'] as Map<String, dynamic>?;
    final tour = departure?['tour'] as Map<String, dynamic>?;
    final guide = row['guide'] as Map<String, dynamic>?;
    return CompletionRequest(
      id: row['id'] as String,
      departureId: row['departure_id'] as String,
      tourTitle: (tour?['title'] as String?) ?? '',
      departureAt: DateTime.parse(departure!['departure_at'] as String),
      guideName: (guide?['full_name'] as String?) ?? '',
      status: CompletionStatus.fromValue(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      reviewedAt: DateTime.tryParse((row['reviewed_at'] as String?) ?? ''),
    );
  }
}
