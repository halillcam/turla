import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/stale_data_banner.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';
import '../../domain/entities/guide_departure.dart';
import '../cubit/guide_home_cubit.dart';
import '../widgets/guide_departure_card.dart';

/// Tur sorumlusunun ana ekranı: atanmış kalkışlar (bugünkü en üstte).
class GuideHomeScreen extends StatelessWidget {
  const GuideHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GuideHomeCubit>()..load(),
      child: const _GuideHomeView(),
    );
  }
}

class _GuideHomeView extends StatelessWidget {
  const _GuideHomeView();

  @override
  Widget build(BuildContext context) {
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
        child: BlocBuilder<GuideHomeCubit, GuideHomeState>(
          builder: (context, state) {
            final cubit = context.read<GuideHomeCubit>();
            if (state.status == GuideHomeStatus.loading) return const StatusView.loading();
            if (state.status == GuideHomeStatus.failure) {
              return StatusView.message(
                message: AppStrings.guideDeparturesLoadError,
                icon: Icons.wifi_off,
                onAction: cubit.refresh,
              );
            }
            return RefreshIndicator(
              onRefresh: cubit.refresh,
              child: ListView(
                padding: AppPaddings.screen,
                children: [
                  Text(
                    '${AppStrings.guideWelcomePrefix} $name',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.isStale)
                    const StaleDataBanner(message: AppStrings.showingCachedDepartures),
                  if (state.isEmpty)
                    const StatusView.message(
                      message: AppStrings.guideNoDepartures,
                      icon: Icons.event_busy,
                    ),
                  ..._section(context, AppStrings.guideToday, state.todayDepartures),
                  ..._section(context, AppStrings.guideUpcoming, state.upcomingDepartures),
                  ..._section(context, AppStrings.guideCompleted, state.completedDepartures),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _section(BuildContext context, String title, List<GuideDeparture> departures) {
    if (departures.isEmpty) return const [];
    return [
      Padding(
        padding: AppPaddings.verticalSm,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      for (final departure in departures)
        GuideDepartureCard(
          departure: departure,
          onTap: () => context.push(AppRoutes.guideDepartureOf(departure.id)),
        ),
    ];
  }
}
