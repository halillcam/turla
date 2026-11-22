import 'package:flutter_test/flutter_test.dart';
import 'package:turla_core/turla_core.dart';

class _FakeRemote implements CityRemoteDataSource {
  _FakeRemote(this.cities);

  List<CityModel> cities;
  bool shouldFail = false;
  int calls = 0;

  @override
  Future<List<CityModel>> fetchCities() async {
    calls++;
    if (shouldFail) throw Exception('ağ hatası');
    return cities;
  }
}

class _FakeLocal implements CityLocalDataSource {
  List<CityModel>? stored;
  int reads = 0;
  int saves = 0;

  @override
  Future<List<CityModel>?> readCities() async {
    reads++;
    return stored;
  }

  @override
  Future<void> saveCities(List<CityModel> cities) async {
    saves++;
    stored = cities;
  }
}

const _maras = CityModel(id: 46, name: 'Kahramanmaraş');
const _adana = CityModel(id: 1, name: 'Adana');

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late CityRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote([_maras, _adana]);
    local = _FakeLocal();
    repository = CityRepositoryImpl(remoteDataSource: remote, localDataSource: local);
  });

  test('önbellek boşsa sunucudan çeker, plaka sırasına dizer ve cihaza kaydeder', () async {
    final cities = await repository.getCities();

    expect(cities.map((city) => city.id), [1, 46]);
    expect(remote.calls, 1);
    expect(local.saves, 1);
    expect(local.stored, [_maras, _adana].toList());
  });

  test('cihazda liste varsa sunucuya istek atmaz', () async {
    local.stored = [_adana, _maras];

    final cities = await repository.getCities();

    expect(cities.length, 2);
    expect(remote.calls, 0);
  });

  test('aynı oturumda ikinci çağrı bellekten döner, cihazdan tekrar okumaz', () async {
    await repository.getCities();
    final readsAfterFirst = local.reads;

    await repository.getCities();

    expect(local.reads, readsAfterFirst);
    expect(remote.calls, 1);
  });

  test('forceRefresh sunucudan yeniden çeker ve önbelleği günceller', () async {
    local.stored = [_adana];
    remote.cities = [_adana, _maras];

    final cities = await repository.getCities(forceRefresh: true);

    expect(cities.length, 2);
    expect(remote.calls, 1);
    expect(local.stored!.length, 2);
  });

  test('sunucuya ulaşılamazsa önbellekteki listeyle devam eder', () async {
    local.stored = [_adana];
    remote.shouldFail = true;

    final cities = await repository.getCities(forceRefresh: true);

    expect(cities.single.name, 'Adana');
  });

  test('ne önbellek ne sunucu varsa CitiesUnavailableException fırlatır', () async {
    remote.shouldFail = true;

    expect(repository.getCities(), throwsA(isA<CitiesUnavailableException>()));
  });

  test('sunucu boş liste dönerse kaydetmez ve hata verir', () async {
    remote.cities = [];

    await expectLater(repository.getCities(), throwsA(isA<CitiesUnavailableException>()));
    expect(local.saves, 0);
  });
}
