import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';

/// Tur sorumlusunun ana ekranı. Katılımcılar, QR okutma ve duyurular Faz 4'te gelecek.
class GuideHomeScreen extends StatelessWidget {
  const GuideHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = context.select((SessionBloc bloc) => bloc.state.profile?.fullName ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.guideHomeTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.signOut,
            onPressed: () => context.read<SessionBloc>().add(const SessionSignOutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppStrings.guideWelcomePrefix} $name', style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              Text(AppStrings.guideComingSoon, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
