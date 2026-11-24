import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'panel_failure.dart';

/// Supabase / ağ hatalarını [PanelFailure]'a çevirerek [action]'ı çalıştırır.
/// Repository'lerin tüm sunucu çağrıları bu fonksiyondan geçer.
Future<T> guardPanel<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on PanelFailure {
    rethrow;
  } on PostgrestException catch (error) {
    throw PanelFailure(PanelErrorMapper.fromPostgrest(error.code, error.message), error);
  } on FunctionException catch (error) {
    throw PanelFailure(PanelErrorMapper.fromFunction(error.status, error.details), error);
  } on StorageException catch (error) {
    throw PanelFailure(PanelErrorMapper.fromStorage(error.statusCode), error);
  } on AuthException catch (error) {
    throw PanelFailure(
      error is AuthRetryableFetchException
          ? PanelFailureReason.network
          : PanelFailureReason.notAllowed,
      error,
    );
  } on ClientException catch (error) {
    throw PanelFailure(PanelFailureReason.network, error);
  } on TimeoutException catch (error) {
    throw PanelFailure(PanelFailureReason.network, error);
  }
}

/// Sunucu hata kodlarının eşlemesi. Ayrı tutulur ki testlerde doğrudan denensin.
abstract final class PanelErrorMapper {
  /// SQL fonksiyonlarının `raise exception` kodları ve PostgREST kodları.
  static PanelFailureReason fromPostgrest(String? code, String message) {
    final byMessage = _byCode[message.trim()];
    if (byMessage != null) return byMessage;
    return switch (code) {
      '42501' => PanelFailureReason.notAllowed, // yetki / RLS
      '23503' => PanelFailureReason.hasTickets, // silinmek istenen satıra bağlı bilet var
      '23514' || '22P02' || '23502' => PanelFailureReason.invalidInput, // check / tip / not null
      'PGRST116' => PanelFailureReason.notFound, // tek satır beklenirken satır yok
      _ => PanelFailureReason.unknown,
    };
  }

  /// create-account Edge Function yanıtları: `{ "code": "..." }`.
  static PanelFailureReason fromFunction(int status, Object? details) {
    final code = details is Map ? details['code'] : null;
    final byCode = code is String ? _byCode[code] : null;
    if (byCode != null) return byCode;
    if (status == 401 || status == 403) return PanelFailureReason.notAllowed;
    if (status == 400) return PanelFailureReason.invalidInput;
    return PanelFailureReason.unknown;
  }

  static PanelFailureReason fromStorage(String? statusCode) => switch (statusCode) {
    '403' || '401' => PanelFailureReason.notAllowed,
    '413' || '415' => PanelFailureReason.invalidImage,
    _ => PanelFailureReason.unknown,
  };

  static const Map<String, PanelFailureReason> _byCode = {
    'not_allowed': PanelFailureReason.notAllowed,
    'unauthorized': PanelFailureReason.notAllowed,
    'company_inactive': PanelFailureReason.companyInactive,
    'company_not_found': PanelFailureReason.notFound,
    'profile_not_found': PanelFailureReason.notFound,
    'request_not_found': PanelFailureReason.notFound,
    'capacity_below_sold_seats': PanelFailureReason.capacityBelowSoldSeats,
    'invalid_guide': PanelFailureReason.invalidGuide,
    'request_already_reviewed': PanelFailureReason.alreadyReviewed,
    'email_exists': PanelFailureReason.emailExists,
    'weak_password': PanelFailureReason.weakPassword,
    'cannot_change_self': PanelFailureReason.cannotChangeSelf,
    'invalid_program': PanelFailureReason.invalidInput,
    'invalid_role': PanelFailureReason.invalidInput,
    'company_required': PanelFailureReason.invalidInput,
    'invalid_full_name': PanelFailureReason.invalidInput,
    'invalid_email': PanelFailureReason.invalidInput,
    'invalid_phone': PanelFailureReason.invalidInput,
    'invalid_body': PanelFailureReason.invalidInput,
  };
}
