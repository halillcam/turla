import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/guide_departure.dart';
import '../../domain/entities/participant.dart';
import '../models/guide_models.dart';

/// Rehberin son çekilen kalkış ve katılımcı listeleri (internet yokken görünsün diye).
abstract interface class GuideLocalDataSource {
  /// Kayıt yoksa veya biçimi eskiyse null.
  Future<List<GuideDeparture>?> readDepartures(String userId);

  Future<void> writeDepartures(String userId, List<GuideDeparture> departures);

  Future<List<Participant>?> readParticipants(String userId, String departureId);

  Future<void> writeParticipants(String userId, String departureId, List<Participant> participants);
}

class GuideLocalDataSourceImpl implements GuideLocalDataSource {
  GuideLocalDataSourceImpl({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _versionKey = 'version';
  static const String _itemsKey = 'items';

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<GuideDeparture>?> readDepartures(String userId) =>
      _read('${StorageKeys.guideDeparturesPrefix}$userId', GuideDepartureModel.fromRow);

  @override
  Future<void> writeDepartures(String userId, List<GuideDeparture> departures) => _write(
    '${StorageKeys.guideDeparturesPrefix}$userId',
    departures.map(GuideDepartureModel.toRow).toList(),
  );

  @override
  Future<List<Participant>?> readParticipants(String userId, String departureId) =>
      _read(_participantsKey(userId, departureId), ParticipantModel.fromRow);

  @override
  Future<void> writeParticipants(
    String userId,
    String departureId,
    List<Participant> participants,
  ) => _write(
    _participantsKey(userId, departureId),
    participants.map(ParticipantModel.toRow).toList(),
  );

  String _participantsKey(String userId, String departureId) =>
      '${StorageKeys.guideParticipantsPrefix}$userId.$departureId';

  Future<List<T>?> _read<T>(String key, T Function(Map<String, dynamic>) fromRow) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json[_versionKey] != CacheVersions.guide) return null;
      return (json[_itemsKey] as List<dynamic>).cast<Map<String, dynamic>>().map(fromRow).toList();
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> _write(String key, List<Map<String, dynamic>> rows) =>
      _preferences.setString(key, jsonEncode({_versionKey: CacheVersions.guide, _itemsKey: rows}));
}
