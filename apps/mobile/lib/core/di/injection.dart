import 'package:get_it/get_it.dart';
import 'package:turla_core/turla_core.dart';

import '../../features/auth/presentation/bloc/session_bloc.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/auth/presentation/cubit/register_cubit.dart';
import '../../features/city_choice/data/datasources/selected_city_local_data_source.dart';
import '../../features/city_choice/data/repositories/selected_city_repository_impl.dart';
import '../../features/city_choice/domain/repositories/selected_city_repository.dart';
import '../../features/city_choice/presentation/cubit/city_choice_cubit.dart';
import '../../features/city_choice/presentation/cubit/selected_city_cubit.dart';
import '../../features/guide/data/datasources/guide_local_data_source.dart';
import '../../features/guide/data/datasources/guide_remote_data_source.dart';
import '../../features/guide/data/repositories/guide_repository_impl.dart';
import '../../features/guide/domain/repositories/guide_repository.dart';
import '../../features/guide/presentation/cubit/departure_cubit.dart';
import '../../features/guide/presentation/cubit/guide_home_cubit.dart';
import '../../features/guide/presentation/cubit/scan_cubit.dart';
import '../../features/live_tour/data/datasources/live_tour_remote_data_source.dart';
import '../../features/live_tour/data/repositories/live_tour_repository_impl.dart';
import '../../features/live_tour/domain/repositories/active_tour_repository.dart';
import '../../features/live_tour/domain/repositories/announcement_repository.dart';
import '../../features/live_tour/domain/repositories/chat_repository.dart';
import '../../features/live_tour/presentation/cubit/active_tour_cubit.dart';
import '../../features/live_tour/presentation/cubit/announcements_cubit.dart';
import '../../features/live_tour/presentation/cubit/chat_cubit.dart';
import '../../features/notifications/data/datasources/device_token_remote_data_source.dart';
import '../../features/notifications/data/datasources/notification_data_sources.dart';
import '../../features/notifications/data/datasources/push_messaging_data_source.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/data/repositories/push_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/repositories/push_repository.dart';
import '../../features/notifications/presentation/cubit/notification_center_cubit.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/tickets/data/datasources/ticket_local_data_source.dart';
import '../../features/tickets/data/datasources/ticket_remote_data_source.dart';
import '../../features/tickets/data/repositories/ticket_repository_impl.dart';
import '../../features/tickets/domain/repositories/ticket_repository.dart';
import '../../features/tickets/presentation/cubit/checkout_cubit.dart';
import '../../features/tickets/presentation/cubit/my_tickets_cubit.dart';
import '../../features/tickets/presentation/cubit/ticket_detail_cubit.dart';
import '../../features/tours/data/datasources/tour_local_data_source.dart';
import '../../features/tours/data/datasources/tour_remote_data_source.dart';
import '../../features/tours/data/repositories/tour_repository_impl.dart';
import '../../features/tours/domain/repositories/tour_repository.dart';
import '../../features/tours/presentation/cubit/tour_detail_cubit.dart';
import '../../features/tours/presentation/cubit/tour_list_cubit.dart';
import '../cache/user_cache_cleaner.dart';

/// Uygulama genelindeki bağımlılık kabı.
final GetIt getIt = GetIt.instance;

/// Bağımlılıkları kaydeder. Supabase ve Firebase başlatıldıktan sonra çağrılmalıdır.
/// [pushMessaging] Firebase yapılandırılmamışsa devre dışı bir örnektir.
///
/// Repository'ler tek örnek (singleton) olarak, ekranlara ait Cubit'ler her
/// ekran açılışında yeni örnek (factory) olarak oluşturulur.
void configureDependencies({required PushMessagingDataSource pushMessaging}) {
  getIt
    // Altyapı
    ..registerLazySingleton<SupabaseClient>(() => TurlaSupabase.client)
    // Repository'ler
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    // İller: ilk istekte sunucudan çekilir, sonra cihazdan okunur.
    ..registerLazySingleton<CityRepository>(
      () => CityRepositoryImpl(
        remoteDataSource: CityRemoteDataSourceImpl(getIt()),
        localDataSource: CityLocalDataSourceImpl(),
      ),
    )
    ..registerLazySingleton<SelectedCityRepository>(
      () => SelectedCityRepositoryImpl(
        localDataSource: SelectedCityLocalDataSourceImpl(),
        authRepository: getIt(),
      ),
    )
    ..registerLazySingleton<TourRepository>(
      () => TourRepositoryImpl(
        remoteDataSource: TourRemoteDataSourceImpl(getIt()),
        localDataSource: TourLocalDataSourceImpl(),
      ),
    )
    // Biletler cihazda kullanıcı bazında saklanır (QR internetsiz açılır).
    ..registerLazySingleton<TicketRepository>(
      () => TicketRepositoryImpl(
        remoteDataSource: TicketRemoteDataSourceImpl(getIt()),
        localDataSource: TicketLocalDataSourceImpl(),
      ),
    )
    // Rehber: okutma internet ister; listeler son haliyle cihazda tutulur.
    ..registerLazySingleton<GuideRepository>(
      () => GuideRepositoryImpl(
        remoteDataSource: GuideRemoteDataSourceImpl(getIt()),
        localDataSource: GuideLocalDataSourceImpl(),
      ),
    )
    // Aktif tur, sohbet ve duyurular: canlı veri, cihazda saklanmaz.
    ..registerLazySingleton<LiveTourRepositoryImpl>(
      () => LiveTourRepositoryImpl(LiveTourRemoteDataSourceImpl(getIt())),
    )
    ..registerLazySingleton<ActiveTourRepository>(() => getIt<LiveTourRepositoryImpl>())
    ..registerLazySingleton<ChatRepository>(() => getIt<LiveTourRepositoryImpl>())
    ..registerLazySingleton<AnnouncementRepository>(() => getIt<LiveTourRepositoryImpl>())
    // Bildirim kutusu cihazda kullanıcı bazında; push sadece Android (FCM).
    ..registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(
        remoteDataSource: NotificationRemoteDataSourceImpl(getIt()),
        localDataSource: NotificationLocalDataSourceImpl(),
      ),
    )
    ..registerLazySingleton<PushRepositoryImpl>(
      () => PushRepositoryImpl(
        messagingDataSource: pushMessaging,
        tokenDataSource: DeviceTokenRemoteDataSourceImpl(getIt()),
      ),
    )
    ..registerLazySingleton<PushRepository>(() => getIt<PushRepositoryImpl>())
    // Uygulama genelinde yaşayan Bloc'lar
    ..registerLazySingleton<SessionBloc>(
      () => SessionBloc(
        getIt(),
        // Çıkışta: önce push token'ı hesaptan ayrılır, sonra cihazdaki kişisel önbellek silinir.
        cleanups: [getIt<PushRepositoryImpl>(), UserCacheCleaner()],
      ),
    )
    ..registerLazySingleton<NotificationCenterCubit>(
      () => NotificationCenterCubit(notificationRepository: getIt(), pushRepository: getIt()),
    )
    ..registerLazySingleton<SelectedCityCubit>(
      () => SelectedCityCubit(selectedCityRepository: getIt(), cityRepository: getIt()),
    )
    // Ekran Cubit'leri
    ..registerFactory<LoginCubit>(() => LoginCubit(getIt()))
    ..registerFactory<RegisterCubit>(() => RegisterCubit(getIt()))
    ..registerFactory<CityChoiceCubit>(() => CityChoiceCubit(getIt()))
    ..registerFactory<TourListCubit>(() => TourListCubit(getIt()))
    ..registerFactory<TourDetailCubit>(() => TourDetailCubit(getIt()))
    ..registerFactory<CheckoutCubit>(() => CheckoutCubit(getIt()))
    ..registerFactory<MyTicketsCubit>(() => MyTicketsCubit(getIt()))
    ..registerFactory<TicketDetailCubit>(() => TicketDetailCubit(getIt()))
    ..registerFactory<GuideHomeCubit>(() => GuideHomeCubit(getIt()))
    ..registerFactory<DepartureCubit>(() => DepartureCubit(getIt()))
    ..registerFactory<ScanCubit>(() => ScanCubit(getIt()))
    ..registerFactory<ActiveTourCubit>(() => ActiveTourCubit(getIt()))
    ..registerFactory<ChatCubit>(() => ChatCubit(getIt()))
    ..registerFactory<AnnouncementsCubit>(() => AnnouncementsCubit(getIt()))
    ..registerFactory<NotificationsCubit>(() => NotificationsCubit(getIt()));
}
