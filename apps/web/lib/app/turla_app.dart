import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../core/constants/strings.dart';
import '../features/home/presentation/screens/home_screen.dart';

/// Web panelinin kök widget'ı.
class TurlaApp extends StatelessWidget {
  const TurlaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.panelTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
