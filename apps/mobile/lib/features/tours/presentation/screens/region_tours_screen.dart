import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/stale_data_banner.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../city_choice/presentation/cubit/selected_city_cubit.dart';
import '../cubit/tour_list_cubit.dart';
import '../widgets/tour_card.dart';

/// Bir bölgenin tüm turları, dikey liste. Turlar aynı önbellekten gelir (20 dk).
class RegionToursScreen extends StatelessWidget {
  const RegionToursScreen({required this.region, super.key});

  final TourRegion region;

  @override
  Widget build(BuildContext context) {
    final cityId = context.read<SelectedCityCubit>().state.cityId;

    return BlocProvider(
      create: (_) {
        final cubit = getIt<TourListCubit>()..showOnlyRegion(region);
        if (cityId != null) cubit.load(cityId);
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(region.label)),
        body: SafeArea(
          child: BlocBuilder<TourListCubit, TourListState>(
            builder: (context, state) {
              final cubit = context.read<TourListCubit>();
              return RefreshIndicator(onRefresh: cubit.refresh, child: _content(context, state));
            },
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, TourListState state) {
    if (state.isLoading) return const StatusView.loading();
    if (state.status == TourListStatus.failure) {
      return StatusView.message(
        message: AppStrings.toursLoadError,
        icon: Icons.wifi_off,
        onAction: context.read<TourListCubit>().refresh,
      );
    }
    final tours = state.visibleTours;
    if (tours.isEmpty) {
      return const StatusView.message(
        message: AppStrings.noToursInRegion,
        icon: Icons.travel_explore,
      );
    }
    return ListView(
      padding: AppPaddings.screen,
      children: [
        if (state.isStale) const StaleDataBanner(),
        for (final tour in tours)
          TourCard(tour: tour, onTap: () => context.push(AppRoutes.tourDetailOf(tour.id))),
      ],
    );
  }
}
