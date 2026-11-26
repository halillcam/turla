import 'package:get_it/get_it.dart';
import 'package:turla_core/turla_core.dart';

import '../../features/announcements/data/repositories/company_announcement_repository_impl.dart';
import '../../features/announcements/domain/repositories/company_announcement_repository.dart';
import '../../features/announcements/presentation/cubit/company_announcements_cubit.dart';
import '../../features/chat/data/repositories/panel_chat_repository_impl.dart';
import '../../features/chat/domain/repositories/panel_chat_repository.dart';
import '../../features/chat/presentation/cubit/panel_chat_cubit.dart';
import '../../features/feedback/data/repositories/feedback_repository_impl.dart';
import '../../features/feedback/domain/repositories/feedback_repository.dart';
import '../../features/feedback/presentation/cubit/feedback_cubit.dart';
import '../../features/auth/data/panel_auth_repository_impl.dart';
import '../../features/auth/domain/panel_auth_repository.dart';
import '../../features/auth/presentation/bloc/session_bloc.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/companies/data/repositories/company_repository_impl.dart';
import '../../features/companies/domain/repositories/company_repository.dart';
import '../../features/companies/presentation/cubit/company_detail_cubit.dart';
import '../../features/companies/presentation/cubit/company_list_cubit.dart';
import '../../features/completions/data/repositories/completion_repository_impl.dart';
import '../../features/completions/domain/repositories/completion_repository.dart';
import '../../features/completions/presentation/cubit/completions_cubit.dart';
import '../../features/staff/data/repositories/account_repository_impl.dart';
import '../../features/staff/domain/repositories/account_repository.dart';
import '../../features/staff/presentation/cubit/staff_cubit.dart';
import '../../features/tickets/data/repositories/ticket_admin_repository_impl.dart';
import '../../features/tickets/domain/repositories/ticket_admin_repository.dart';
import '../../features/tickets/presentation/cubit/participants_cubit.dart';
import '../../features/tours/data/repositories/tour_admin_repository_impl.dart';
import '../../features/tours/data/services/image_resizer.dart';
import '../../features/tours/domain/entities/departure.dart';
import '../../features/tours/domain/repositories/tour_admin_repository.dart';
import '../../features/tours/presentation/cubit/departures_cubit.dart';
import '../../features/tours/presentation/cubit/tour_info_cubit.dart';
import '../../features/tours/presentation/cubit/tour_list_cubit.dart';
import '../../features/tours/presentation/cubit/tour_program_cubit.dart';

/// Uygulama genelindeki bağımlılık kabı.
final GetIt getIt = GetIt.instance;

/// Bağımlılıkları kaydeder. Supabase başlatıldıktan sonra çağrılmalıdır.
///
/// Repository'ler tek örnek; ekran Cubit'leri her açılışta yeni örnek
/// (firma / tur kimliği parametre olarak verilir).
void configureDependencies() {
  getIt
    // Altyapı
    ..registerLazySingleton<SupabaseClient>(() => TurlaSupabase.client)
    ..registerLazySingleton<ImageResizer>(ImageResizer.new)
    // Repository'ler
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerLazySingleton<CityRepository>(
      () => CityRepositoryImpl(
        remoteDataSource: CityRemoteDataSourceImpl(getIt()),
        localDataSource: CityLocalDataSourceImpl(),
      ),
    )
    ..registerLazySingleton<CompanyRepository>(() => CompanyRepositoryImpl(getIt()))
    ..registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(getIt()))
    ..registerLazySingleton<TourAdminRepository>(() => TourAdminRepositoryImpl(getIt()))
    ..registerLazySingleton<CompletionRepository>(() => CompletionRepositoryImpl(getIt()))
    ..registerLazySingleton<TicketAdminRepository>(() => TicketAdminRepositoryImpl(getIt()))
    ..registerLazySingleton<PanelChatRepository>(() => PanelChatRepositoryImpl(getIt()))
    ..registerLazySingleton<CompanyAnnouncementRepository>(
      () => CompanyAnnouncementRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<FeedbackRepository>(() => FeedbackRepositoryImpl(getIt()))
    ..registerLazySingleton<PanelAuthRepository>(
      () => PanelAuthRepositoryImpl(
        authRepository: getIt(),
        companyRepository: getIt(),
        authStates: getIt<SupabaseClient>().auth.onAuthStateChange,
      ),
    )
    // Uygulama genelinde yaşayan Bloc
    ..registerLazySingleton<SessionBloc>(() => SessionBloc(getIt()))
    // Ekran Cubit'leri
    ..registerFactory<LoginCubit>(() => LoginCubit(getIt()))
    ..registerFactory<CompanyListCubit>(
      () => CompanyListCubit(repository: getIt(), cityRepository: getIt()),
    )
    ..registerFactoryParam<CompanyDetailCubit, String, void>(
      (companyId, _) => CompanyDetailCubit(
        companyId: companyId,
        companyRepository: getIt(),
        accountRepository: getIt(),
        cityRepository: getIt(),
      ),
    )
    ..registerFactoryParam<StaffCubit, String, void>(
      (companyId, _) => StaffCubit(companyId: companyId, accountRepository: getIt()),
    )
    ..registerFactoryParam<TourListCubit, String, void>(
      (companyId, _) => TourListCubit(companyId: companyId, repository: getIt()),
    )
    ..registerFactoryParam<TourInfoCubit, String, String?>(
      (companyId, tourId) => TourInfoCubit(
        companyId: companyId,
        tourId: tourId,
        repository: getIt(),
        cityRepository: getIt(),
        imageResizer: getIt(),
      ),
    )
    ..registerFactoryParam<TourProgramCubit, String, void>(
      (tourId, _) => TourProgramCubit(tourId: tourId, repository: getIt()),
    )
    ..registerFactoryParam<DeparturesCubit, String, String>(
      (companyId, tourId) => DeparturesCubit(
        companyId: companyId,
        tourId: tourId,
        tourRepository: getIt(),
        accountRepository: getIt(),
      ),
    )
    ..registerFactoryParam<ParticipantsCubit, String, Departure>(
      (companyId, departure) => ParticipantsCubit(
        companyId: companyId,
        departure: departure,
        ticketRepository: getIt(),
        accountRepository: getIt(),
      ),
    )
    ..registerFactoryParam<CompletionsCubit, String, void>(
      (companyId, _) => CompletionsCubit(companyId: companyId, repository: getIt()),
    )
    ..registerFactoryParam<PanelChatCubit, String, bool>(
      (departureId, canWrite) =>
          PanelChatCubit(departureId: departureId, canWrite: canWrite, repository: getIt()),
    )
    ..registerFactoryParam<CompanyAnnouncementsCubit, String?, void>(
      (companyId, _) => CompanyAnnouncementsCubit(
        companyId: companyId,
        repository: getIt(),
        companyRepository: getIt(),
      ),
    )
    ..registerFactoryParam<FeedbackCubit, String?, void>(
      (companyId, _) => FeedbackCubit(companyId: companyId, repository: getIt()),
    );
}
