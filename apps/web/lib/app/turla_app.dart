import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:turla_core/turla_core.dart';

import '../core/constants/strings.dart';
import '../core/di/injection.dart';
import '../features/auth/presentation/bloc/session_bloc.dart';
import 'router/app_router.dart';

/// Web panelinin kök widget'ı.
class TurlaApp extends StatefulWidget {
  const TurlaApp({super.key});

  @override
  State<TurlaApp> createState() => _TurlaAppState();
}

class _TurlaAppState extends State<TurlaApp> {
  static const Locale _turkish = Locale('tr', 'TR');

  late final SessionBloc _sessionBloc = getIt<SessionBloc>()..add(const SessionStarted());
  late final AppRouter _appRouter = AppRouter(sessionBloc: _sessionBloc);

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _sessionBloc,
      child: MaterialApp.router(
        title: AppStrings.panelTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _appRouter.router,
        locale: _turkish,
        supportedLocales: const [_turkish],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
