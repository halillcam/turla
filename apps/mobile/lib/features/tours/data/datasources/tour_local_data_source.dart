import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/tour.dart';
import '../models/tour_model.dart';

/// Önbellekteki liste ve kaydedilme zamanı.
class CachedTourList {
  const CachedTourList({required this.tours, required this.savedAt});

  final List<Tour> tours;
  final DateTime savedAt;
}

/// İl bazında tur listesini cihazda saklar. Görseller burada değil, görsel
/// önbelleğinde (TurlaImageCacheManager) tutulur; bu yüzden kapladığı yer KB düzeyindedir.
abstract interface class TourLocalDataSource {
  Future<CachedTourList?> read(int cityId);

  Future<void> write(int cityId, List<Tour> tours);
}

class TourLocalDataSourceImpl implements TourLocalDataSource {
  TourLocalDataSourceImpl({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _versionKey = 'version';
  static const String _savedAtKey = 'savedAt';
  static const String _toursKey = 'tours';

  final SharedPreferencesAsync _preferences;

  String _key(int cityId) => '${StorageKeys.toursByCityPrefix}$cityId';

  @override
  Future<CachedTourList?> read(int cityId) async {
    final raw = await _preferences.getString(_key(cityId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json[_versionKey] != CacheVersions.tours) return null;
      return CachedTourList(
        savedAt: DateTime.parse(json[_savedAtKey] as String),
        tours: (json[_toursKey] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(TourModel.fromRow)
            .toList(),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> write(int cityId, List<Tour> tours) => _preferences.setString(
    _key(cityId),
    jsonEncode({
      _versionKey: CacheVersions.tours,
      _savedAtKey: DateTime.now().toUtc().toIso8601String(),
      _toursKey: tours.map(TourModel.toRow).toList(),
    }),
  );
}
