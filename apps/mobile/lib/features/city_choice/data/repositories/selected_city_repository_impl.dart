import 'package:turla_core/turla_core.dart';

import '../../domain/repositories/selected_city_repository.dart';
import '../datasources/selected_city_local_data_source.dart';

class SelectedCityRepositoryImpl implements SelectedCityRepository {
  const SelectedCityRepositoryImpl({
    required SelectedCityLocalDataSource localDataSource,
    required AuthRepository authRepository,
  }) : _local = localDataSource,
       _auth = authRepository;

  final SelectedCityLocalDataSource _local;
  final AuthRepository _auth;

  @override
  Future<int?> readSelectedCityId() async {
    try {
      return await _local.read();
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveSelectedCityId(int cityId) async {
    await _local.write(cityId);
    try {
      // Oturum yoksa bir şey yapmaz. Ağ hatası seçimi engellemez.
      await _auth.updateSelectedCity(cityId);
    } on AuthFailure {
      // Profil bir sonraki seçimde güncellenir.
    }
  }
}
