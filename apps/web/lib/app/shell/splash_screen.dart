import 'package:flutter/material.dart';

import '../../core/widgets/status_view.dart';

/// Oturum kontrol edilirken gösterilir.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: StatusView.loading());
}
