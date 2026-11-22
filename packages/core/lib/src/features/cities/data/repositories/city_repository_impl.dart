import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../datasources/city_local_data_source.dart';
import '../datasources/city_remote_data_source.dart';
import '../models/city_model.dart';

/// Önce bellekteki, sonra cihazdaki listeyi kullanır; ikisi de yoksa sunucudan
/// çekip cihaza kaydeder. Sunucuya ulaşılamazsa eldeki önbellekle devam eder.
class CityRepositoryImpl implements CityRepository {
  CityRepositoryImpl({
    required CityRemoteDataSource remoteDataSource,
    required CityLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final CityRemoteDataSource _remote;
  final CityLocalDataSource _local;

  /// Uygulama açıkken tekrar tekrar cihazdan okumamak için.
  List<City>? _memoryCache;

  @override
  Future<List<City>> getCities({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final inMemory = _memoryCache;
      if (inMemory != null) return inMemory;

      final cached = await _readLocalSafely();
      if (cached != null) return _remember(cached);
    }

    try {
      final fetched = await _remote.fetchCities();
      if (fetched.isEmpty) {
        throw const CitiesUnavailableException();
      }
      await _saveLocalSafely(fetched);
      return _remember(fetched);
    } on Object catch (error) {
      // Sunucuya ulaşılamadı: zorla yenileme istense bile eldeki liste kullanılır.
      final fallback = _memoryCache ?? _toEntities(await _readLocalSafely());
      if (fallback != null) return fallback;
      throw CitiesUnavailableException(error);
    }
  }

  Future<List<CityModel>?> _readLocalSafely() async {
    try {
      return await _local.readCities();
    } on Object {
      return null;
    }
  }

  Future<void> _saveLocalSafely(List<CityModel> cities) async {
    try {
      await _local.saveCities(cities);
    } on Object {
      // Önbelleğe yazılamaması akışı bozmaz; bir sonraki açılışta tekrar denenir.
    }
  }

  List<City> _remember(List<CityModel> models) {
    final cities = _toEntities(models)!;
    _memoryCache = cities;
    return cities;
  }

  List<City>? _toEntities(List<CityModel>? models) {
    if (models == null) return null;
    final cities = models.map((model) => model.toEntity()).toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return List.unmodifiable(cities);
  }
}
