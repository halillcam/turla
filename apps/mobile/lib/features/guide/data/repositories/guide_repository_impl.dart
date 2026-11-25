import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/check_in_result.dart';
import '../../domain/entities/guide_departure.dart';
import '../../domain/entities/guide_failure.dart';
import '../../domain/entities/participant.dart';
import '../../domain/repositories/guide_repository.dart';
import '../datasources/guide_local_data_source.dart';
import '../datasources/guide_remote_data_source.dart';

class GuideRepositoryImpl implements GuideRepository {
  GuideRepositoryImpl({
    required GuideRemoteDataSource remoteDataSource,
    required GuideLocalDataSource localDataSource,
    DateTime Function()? clock,
  }) : _remote = remoteDataSource,
       _local = localDataSource,
       _now = clock ?? DateTime.now;

  final GuideRemoteDataSource _remote;
  final GuideLocalDataSource _local;
  final DateTime Function() _now;
  final StreamController<List<GuideDeparture>> _departureChanges = StreamController.broadcast();

  @override
  Stream<List<GuideDeparture>> get departureChanges => _departureChanges.stream;

  @override
  Future<List<GuideDeparture>?> getCachedDepartures() async {
    final userId = _remote.currentUserId;
    if (userId == null) return null;
    return _safe(() => _local.readDepartures(userId));
  }

  @override
  Future<List<GuideDeparture>> refreshDepartures() async {
    final userId = _requireUser();
    final departures = await _guard(_remote.fetchDepartures);
    await _saveDepartures(userId, departures);
    return departures;
  }

  @override
  Future<List<Participant>?> getCachedParticipants(String departureId) async {
    final userId = _remote.currentUserId;
    if (userId == null) return null;
    return _safe(() => _local.readParticipants(userId, departureId));
  }

  @override
  Future<List<Participant>> refreshParticipants(String departureId) async {
    final userId = _requireUser();
    final participants = await _guard(() => _remote.fetchParticipants(departureId));
    await _safe(() => _local.writeParticipants(userId, departureId, participants));
    // Sayılar katılımcı listesinden güncellenir; ana ekran ayrıca istek atmaz.
    await _updateDeparture(
      userId,
      departureId,
      (departure) => departure.copyWith(
        ticketCount: participants.length,
        checkedInCount: participants.where((participant) => participant.hasArrived).length,
      ),
    );
    return participants;
  }

  @override
  Future<CheckInResult> scanTicket({required String departureId, required String code}) async {
    final userId = _requireUser();
    final result = await _guard(
      () => _remote.scanTicket(departureId: departureId, code: code.trim()),
    );
    if (result.isSuccess) await _markArrived(userId, departureId, result, CheckInMethod.qr);
    return result;
  }

  @override
  Future<CheckInResult> checkInManually(String ticketId) async {
    final userId = _requireUser();
    final result = await _guard(() => _remote.checkInManually(ticketId));
    if (result.isSuccess) {
      final departureId = await _departureOfTicket(userId, ticketId);
      if (departureId != null) {
        await _markArrived(userId, departureId, result, CheckInMethod.manual);
      }
    }
    return result;
  }

  @override
  Future<void> requestCompletion(String departureId) async {
    final userId = _requireUser();
    await _guard(() => _remote.requestCompletion(departureId));
    await _updateDeparture(
      userId,
      departureId,
      (departure) => departure.copyWith(
        status: DepartureStatus.finishRequested,
        lastRequestStatus: CompletionRequestStatus.pending,
      ),
    );
  }

  /// Okutma başarılı: cihazdaki katılımcı ve kalkış sayısı yeniden istek atmadan güncellenir.
  Future<void> _markArrived(
    String userId,
    String departureId,
    CheckInResult result,
    CheckInMethod method,
  ) async {
    final at = result.scannedAt ?? _now();
    final participants = await _safe(() => _local.readParticipants(userId, departureId));
    if (participants != null) {
      final updated = [
        for (final participant in participants)
          participant.ticketId == result.ticketId ? participant.checkedIn(at, method) : participant,
      ];
      await _safe(() => _local.writeParticipants(userId, departureId, updated));
    }
    await _updateDeparture(
      userId,
      departureId,
      (departure) => departure.copyWith(checkedInCount: departure.checkedInCount + 1),
    );
  }

  /// Elle işaretlemede bilet hangi kalkışın? Cihazdaki katılımcı listelerinden bulunur.
  Future<String?> _departureOfTicket(String userId, String ticketId) async {
    final departures = await _safe(() => _local.readDepartures(userId)) ?? const [];
    for (final departure in departures) {
      final participants = await _safe(() => _local.readParticipants(userId, departure.id));
      if (participants?.any((participant) => participant.ticketId == ticketId) ?? false) {
        return departure.id;
      }
    }
    return null;
  }

  Future<void> _updateDeparture(
    String userId,
    String departureId,
    GuideDeparture Function(GuideDeparture) update,
  ) async {
    final departures = await _safe(() => _local.readDepartures(userId));
    if (departures == null) return;
    await _saveDepartures(userId, [
      for (final departure in departures)
        departure.id == departureId ? update(departure) : departure,
    ]);
  }

  Future<void> _saveDepartures(String userId, List<GuideDeparture> departures) async {
    await _safe(() => _local.writeDepartures(userId, departures));
    _departureChanges.add(departures);
  }

  String _requireUser() {
    final userId = _remote.currentUserId;
    if (userId == null) throw const GuideFailure(GuideFailureReason.notSignedIn);
    return userId;
  }

  /// Cihaz okuma/yazma hatası işlemi bozmaz.
  Future<T?> _safe<T>(Future<T?> Function() action) async {
    try {
      return await action();
    } on Object {
      return null;
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on GuideFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw GuideFailure(GuideErrorMapper.fromPostgrest(error.code, error.message), error);
    } on ClientException catch (error) {
      throw GuideFailure(GuideFailureReason.network, error);
    } on TimeoutException catch (error) {
      throw GuideFailure(GuideFailureReason.network, error);
    } on AuthException catch (error) {
      throw GuideFailure(
        error is AuthRetryableFetchException
            ? GuideFailureReason.network
            : GuideFailureReason.notSignedIn,
        error,
      );
    }
  }
}

/// Sunucu hata kodlarının (`raise exception '<kod>'`) eşlemesi.
abstract final class GuideErrorMapper {
  static GuideFailureReason fromPostgrest(String? code, String message) {
    final byMessage = _byCode[message.trim()];
    if (byMessage != null) return byMessage;
    return switch (code) {
      '42501' => GuideFailureReason.notAllowed,
      _ => GuideFailureReason.unknown,
    };
  }

  static const Map<String, GuideFailureReason> _byCode = {
    'not_allowed': GuideFailureReason.notAllowed,
    'departure_not_found': GuideFailureReason.departureNotFound,
    'departure_not_active': GuideFailureReason.departureNotActive,
    'departure_not_started': GuideFailureReason.departureNotStarted,
    'ticket_not_found': GuideFailureReason.ticketNotFound,
  };
}
