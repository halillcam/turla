import 'package:get_it/get_it.dart';
import 'package:turla_core/turla_core.dart';

/// Uygulama genelindeki bağımlılık kabı.
final GetIt getIt = GetIt.instance;

/// Bağımlılıkları kaydeder. Supabase başlatıldıktan sonra çağrılmalıdır.
///
/// Yeni bir feature eklendiğinde datasource → repository → bloc sırasıyla
/// buraya kaydedilir.
void configureDependencies() {
  getIt
    ..registerLazySingleton<SupabaseClient>(() => TurlaSupabase.client)
    // İller: ilk istekte sunucudan çekilir, sonra cihazdan okunur.
    ..registerLazySingleton<CityRepository>(
      () => CityRepositoryImpl(
        remoteDataSource: CityRemoteDataSourceImpl(getIt<SupabaseClient>()),
        localDataSource: CityLocalDataSourceImpl(),
      ),
    );
}
