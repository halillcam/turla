import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:turla_core/turla_core.dart';

import 'app/turla_app.dart';
import 'core/di/injection.dart';
import 'features/notifications/data/datasources/push_messaging_data_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const ConfigErrorApp());
    return;
  }

  Intl.defaultLocale = 'tr_TR';
  await initializeDateFormatting('tr_TR');
  await TurlaSupabase.initialize();
  // google-services.json yoksa push kapalı başlar; uygulama yine çalışır.
  final pushMessaging = await FirebasePushMessagingDataSource.initialize();
  configureDependencies(pushMessaging: pushMessaging);
  Bloc.observer = const TurlaBlocObserver();

  runApp(const TurlaApp());
}
