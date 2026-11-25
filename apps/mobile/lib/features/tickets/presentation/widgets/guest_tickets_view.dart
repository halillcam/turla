import 'package:flutter/material.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/status_view.dart';

/// Misafir Turlarım'a girince: giriş daveti.
class GuestTicketsView extends StatelessWidget {
  const GuestTicketsView({required this.onLogin, super.key});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return StatusView.message(
      message: AppStrings.guestTicketsMessage,
      icon: Icons.confirmation_number_outlined,
      onAction: onLogin,
      actionLabel: AppStrings.loginButton,
    );
  }
}
