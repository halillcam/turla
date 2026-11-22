import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/core_strings.dart';
import '../constants/paddings.dart';
import '../constants/sizes.dart';
import '../theme/app_theme.dart';

/// `.env` ayarları eksikse uygulama yerine gösterilen ekran.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: CoreStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: AppPaddings.allXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_outlined, size: AppSizes.iconXl, color: AppColors.warning),
                SizedBox(height: AppSpacing.lg),
                Text(CoreStrings.missingEnvTitle, textAlign: TextAlign.center),
                SizedBox(height: AppSpacing.sm),
                Text(CoreStrings.missingEnvMessage, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
