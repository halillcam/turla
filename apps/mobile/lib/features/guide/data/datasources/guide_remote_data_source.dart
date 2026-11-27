import 'package:turla_core/turla_core.dart';

import '../../domain/entities/check_in_result.dart';
import '../../domain/entities/guide_departure.dart';
import '../../domain/entities/participant.dart';
import '../models/guide_models.dart';

/// Rehber işlemlerinin sunucu tarafı. Bilet durumları sadece RPC ile değişir.
abstract interface class GuideRemoteDataSource {
  /// Oturumdaki kullanıcı; giriş yapılmamışsa null.
  String? get currentUserId;

  Future<List<GuideDeparture>> fetchDepartures();

  Future<List<Participant>> fetchParticipants(String departureId);

  Future<CheckInResult> scanTicket({required String departureId, required String code});

  Future<CheckInResult> checkInManually(String ticketId);

  Future<void> requestCompletion(String departureId);
}

class GuideRemoteDataSourceImpl implements GuideRemoteDataSource {
  const GuideRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<GuideDeparture>> fetchDepartures() async {
    final rows = await _client.rpc<List<dynamic>>('guide_departures');
    return rows.cast<Map<String, dynamic>>().map(GuideDepartureModel.fromRow).toList();
  }

  @override
  Future<List<Participant>> fetchParticipants(String departureId) async {
    // İptal edilen biletler listeye gelmez; RLS sadece atanmış tarihin biletlerini verir.
    final rows = await _client
        .from('tickets')
        .select(ParticipantModel.columns)
        .eq('departure_id', departureId)
        .neq('status', TicketStatus.cancelled.value)
        .order('passenger_name', ascending: true);
    return rows.map(ParticipantModel.fromRow).toList();
  }

  @override
  Future<CheckInResult> scanTicket({required String departureId, required String code}) async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'scan_ticket',
      params: {'p_departure_id': departureId, 'p_qr_token': code},
    );
    return CheckInResultModel.fromJson(json);
  }

  @override
  Future<CheckInResult> checkInManually(String ticketId) async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'check_in_manually',
      params: {'p_ticket_id': ticketId},
    );
    return CheckInResultModel.fromJson(json);
  }

  @override
  Future<void> requestCompletion(String departureId) async {
    await _client.rpc<dynamic>(
      'request_departure_completion',
      params: {'p_departure_id': departureId},
    );
  }
}
