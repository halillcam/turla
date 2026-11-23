import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:turla_core/turla_core.dart';

import '../core/di/injection.dart';
import '../features/auth/presentation/bloc/session_bloc.dart';
import '../features/auth/presentation/utils/auth_failure_message.dart';
import '../features/city_choice/presentation/cubit/selected_city_cubit.dart';
import 'router/app_router.dart';

/// Mobil uygulamanın kök widget'ı. Oturum ve seçili il uygulama boyunca yaşar.
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
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _sessionBloc = getIt<SessionBloc>()..add(const SessionStarted());
    _selectedCityCubit = getIt<SelectedCityCubit>()..load();
    _appRouter = AppRouter(sessionBloc: _sessionBloc, selectedCityCubit: _selectedCityCubit);
  }

  @override
  void dispose() {
    _appRouter.dispose();
    _sessionBloc.close();
    _selectedCityCubit.close();
    super.dispose();
  }

  void _onSessionChanged(BuildContext context, SessionState state) {
    final profile = state.profile;
    if (profile != null) _selectedCityCubit.adoptFromProfile(profile);

    final notice = state.notice;
    if (notice != null) {
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(notice.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _sessionBloc),
        BlocProvider.value(value: _selectedCityCubit),
      ],
      child: BlocListener<SessionBloc, SessionState>(
        listener: _onSessionChanged,
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
