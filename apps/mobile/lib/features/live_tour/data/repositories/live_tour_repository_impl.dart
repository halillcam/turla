import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/active_tour.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/live_tour_failure.dart';
import '../../domain/repositories/active_tour_repository.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/live_tour_remote_data_source.dart';

/// Aktif tur, sohbet ve duyurular tek uzak kaynaktan gelir; üç arayüzü birlikte uygular.
/// Cihazda saklanmaz: canlı veridir ve tur bitince sohbet gizlenir.
class LiveTourRepositoryImpl
    implements ActiveTourRepository, ChatRepository, AnnouncementRepository {
  LiveTourRepositoryImpl(this._remote);

  final LiveTourRemoteDataSource _remote;

  @override
  String? get currentUserId => _remote.currentUserId;

  @override
  Future<ActiveTour> fetch(String departureId) =>
      _guard(() => _remote.fetchActiveTour(departureId));

  @override
  Future<List<ChatMessage>> fetchPage(String departureId, {DateTime? before}) => _guard(
    () => _remote.fetchMessages(departureId, before: before, limit: ChatRepository.pageSize),
  );

  @override
  Future<ChatMessage> send(String departureId, String body) async {
    final text = body.trim();
    if (text.length > ChatMessage.maxLength) {
      throw const LiveTourFailure(LiveTourFailureReason.messageTooLong);
    }
    return _guard(() => _remote.sendMessage(departureId, text));
  }

  @override
  Future<void> delete(String messageId) => _guard(() => _remote.deleteMessage(messageId));

  @override
  Stream<ChatMessage> watch(String departureId) => _remote.watchMessages(departureId);

  @override
  Future<List<Announcement>> fetchAnnouncements(String departureId) =>
      _guard(() => _remote.fetchAnnouncements(departureId));

  @override
  Future<Announcement> sendAnnouncement(String departureId, String body) async {
    final text = body.trim();
    if (text.length > Announcement.maxLength) {
      throw const LiveTourFailure(LiveTourFailureReason.messageTooLong);
    }
    return _guard(() => _remote.sendAnnouncement(departureId, text));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    if (_remote.currentUserId == null) {
      throw const LiveTourFailure(LiveTourFailureReason.notSignedIn);
    }
    try {
      return await action().timeout(AppDurations.requestTimeout);
    } on LiveTourFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw LiveTourFailure(LiveTourErrorMapper.fromPostgrest(error.code, error.message), error);
    } on ClientException catch (error) {
      throw LiveTourFailure(LiveTourFailureReason.network, error);
    } on TimeoutException catch (error) {
      throw LiveTourFailure(LiveTourFailureReason.network, error);
    } on AuthException catch (error) {
      throw LiveTourFailure(
        error is AuthRetryableFetchException
            ? LiveTourFailureReason.network
            : LiveTourFailureReason.notSignedIn,
        error,
      );
    }
  }
}

/// Sunucu hata kodlarının (`raise exception '<kod>'`, RLS, kısıt) eşlemesi.
abstract final class LiveTourErrorMapper {
  static LiveTourFailureReason fromPostgrest(String? code, String message) {
    final byMessage = _byCode[message.trim()];
    if (byMessage != null) return byMessage;
    return switch (code) {
      // RLS: sohbet kapandı (tur bitti) ya da QR okutulmadı.
      '42501' => LiveTourFailureReason.notAllowed,
      // Karakter sınırı (check kısıtı).
      '23514' => LiveTourFailureReason.messageTooLong,
      _ => LiveTourFailureReason.unknown,
    };
  }

  static const Map<String, LiveTourFailureReason> _byCode = {
    'not_allowed': LiveTourFailureReason.notAllowed,
    'departure_not_active': LiveTourFailureReason.departureNotActive,
    'rate_limited': LiveTourFailureReason.rateLimited,
  };
}
