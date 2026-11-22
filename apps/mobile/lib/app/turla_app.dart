import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../features/home/presentation/screens/home_screen.dart';

/// Mobil uygulamanın kök widget'ı.
class TurlaApp extends StatelessWidget {
  const TurlaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: CoreStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
