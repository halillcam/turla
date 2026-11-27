import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:turla_core/turla_core.dart';

import '../core/constants/strings.dart';
import '../core/di/injection.dart';
import '../features/auth/presentation/bloc/session_bloc.dart';
import '../features/auth/presentation/utils/auth_failure_message.dart';
import '../features/city_choice/presentation/cubit/selected_city_cubit.dart';
import '../features/live_tour/presentation/screens/announcements_screen.dart';
import '../features/notifications/presentation/cubit/notification_center_cubit.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';

/// Mobil uygulamanın kök widget'ı. Oturum, seçili il ve bildirim merkezi
/// uygulama boyunca yaşar.
class TurlaApp extends StatefulWidget {
  const TurlaApp({super.key});

  @override
  State<TurlaApp> createState() => _TurlaAppState();
}

class _TurlaAppState extends State<TurlaApp> {
  static const Locale _turkish = Locale('tr', 'TR');

  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final SessionBloc _sessionBloc;
  late final SelectedCityCubit _selectedCityCubit;
  late final NotificationCenterCubit _notificationCenter;
  late final AppRouter _appRouter;
  StreamSubscription<void>? _passwordRecovery;

  @override
  void initState() {
    super.initState();
    _sessionBloc = getIt<SessionBloc>()..add(const SessionStarted());
    _selectedCityCubit = getIt<SelectedCityCubit>()..load();
    _notificationCenter = getIt<NotificationCenterCubit>();
    _appRouter = AppRouter(sessionBloc: _sessionBloc, selectedCityCubit: _selectedCityCubit);
    // Şifre sıfırlama bağlantısıyla açıldı: oturum kuruldu, yeni şifre ekranı açılır.
    _passwordRecovery = getIt<AuthRepository>().passwordRecoveryRequests.listen(
      (_) => _appRouter.router.go(AppRoutes.resetPassword),
    );
  }

  @override
  void dispose() {
    _passwordRecovery?.cancel();
    _appRouter.dispose();
    _sessionBloc.close();
    _selectedCityCubit.close();
    _notificationCenter.close();
    super.dispose();
  }

  void _onSessionChanged(BuildContext context, SessionState state) {
    final profile = state.profile;
    if (profile != null) _selectedCityCubit.adoptFromProfile(profile);
    _notificationCenter.sessionChanged(isCustomer: profile?.role == UserRole.customer);

    final notice = state.notice;
    if (notice != null) {
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(notice.message)));
    }
  }

  /// Push'a dokunuldu: duyurunun turu açılır (tur yoksa bildirim kutusu).
  void _onOpenRequest(OpenRequest request) {
    final departureId = request.departureId;
    if (departureId == null) {
      _appRouter.router.push(AppRoutes.notifications);
    } else {
      _openAnnouncements(departureId);
    }
  }

  void _openAnnouncements(String departureId) => _appRouter.router.push(
    AppRoutes.customerAnnouncementsOf(departureId),
    extra: const AnnouncementsScreenArgs(),
  );

  /// Uygulama açıkken gelen bildirim kısa mesaj olarak gösterilir.
  void _onForeground(ForegroundNotice notice) {
    final departureId = notice.departureId;
    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${notice.title}: ${notice.body}'),
          action: departureId == null
              ? null
              : SnackBarAction(
                  label: AppStrings.show,
                  onPressed: () => _openAnnouncements(departureId),
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _sessionBloc),
        BlocProvider.value(value: _selectedCityCubit),
        BlocProvider.value(value: _notificationCenter),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<SessionBloc, SessionState>(listener: _onSessionChanged),
          BlocListener<NotificationCenterCubit, NotificationCenterState>(
            listenWhen: (previous, current) =>
                current.openRequest != null && previous.openRequest != current.openRequest,
            listener: (_, state) => _onOpenRequest(state.openRequest!),
          ),
          BlocListener<NotificationCenterCubit, NotificationCenterState>(
            listenWhen: (previous, current) =>
                current.foreground != null && previous.foreground != current.foreground,
            listener: (_, state) => _onForeground(state.foreground!),
          ),
        ],
        child: MaterialApp.router(
          title: CoreStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          scaffoldMessengerKey: _messengerKey,
          routerConfig: _appRouter.router,
          locale: _turkish,
          supportedLocales: const [_turkish],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    );
  }
}
