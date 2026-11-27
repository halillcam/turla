import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/page_header.dart';
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
                padding: AppPaddings.listBody,
                children: [
                  PageHeader(
                    title: '${AppStrings.guideWelcomePrefix} $name',
                    padding: AppPaddings.guideHeader,
                    trailing: IconButton(
                      tooltip: AppStrings.signOut,
                      onPressed: () =>
                          context.read<SessionBloc>().add(const SessionSignOutRequested()),
                      icon: const RoundIcon(icon: Icons.logout),
                    ),
                  ),
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
      SectionHeader(title: title.turkishUpper, padding: AppPaddings.verticalSm),
      for (final departure in departures)
        GuideDepartureCard(
          departure: departure,
          onTap: () => context.push(AppRoutes.guideDepartureOf(departure.id)),
        ),
    ];
  }
}
