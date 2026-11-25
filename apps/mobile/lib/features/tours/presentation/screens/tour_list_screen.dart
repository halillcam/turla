import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../city_choice/presentation/cubit/selected_city_cubit.dart';
import '../cubit/tour_list_cubit.dart';
import '../widgets/region_section_view.dart';
import '../../../../core/widgets/stale_data_banner.dart';
import '../widgets/tour_list_header.dart';

class TourListScreen extends StatelessWidget {
  const TourListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cityId = context.read<SelectedCityCubit>().state.cityId;

    return BlocProvider(
      create: (_) {
        final cubit = getIt<TourListCubit>();
        if (cityId != null) cubit.load(cityId);
        return cubit;
      },
      // Şehir değişince liste yeniden yüklenir.
      child: BlocListener<SelectedCityCubit, SelectedCityState>(
        listenWhen: (previous, current) => previous.cityId != current.cityId,
        listener: (context, state) {
          final newCityId = state.cityId;
          if (newCityId != null) context.read<TourListCubit>().load(newCityId);
        },
        child: const _TourListView(),
      ),
    );
  }
}

class _TourListView extends StatelessWidget {
  const _TourListView();

  @override
  Widget build(BuildContext context) {
    final cityName = context.select(
      (SelectedCityCubit cubit) => cubit.state.city?.name ?? AppStrings.noCitySelected,
    );

    return Scaffold(
      appBar: AppBar(title: const Text(CoreStrings.appName)),
      body: SafeArea(
        child: BlocBuilder<TourListCubit, TourListState>(
          builder: (context, state) {
            final cubit = context.read<TourListCubit>();
            return RefreshIndicator(
              onRefresh: cubit.refresh,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: AppPaddings.screen,
                    sliver: SliverToBoxAdapter(
                      child: TourListHeader(
                        cityName: cityName,
                        onChangeCity: () => context.push(AppRoutes.citySelection),
                        onSearchChanged: cubit.search,
                      ),
                    ),
                  ),
                  ..._content(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, TourListState state) {
    if (state.isLoading) {
      return const [SliverFillRemaining(hasScrollBody: false, child: StatusView.loading())];
    }
    if (state.status == TourListStatus.failure) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StatusView.message(
            message: AppStrings.toursLoadError,
            icon: Icons.wifi_off,
            onAction: context.read<TourListCubit>().refresh,
          ),
        ),
      ];
    }

    final sections = state.sections;
    if (sections.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StatusView.message(
            message: state.tours.isEmpty ? AppStrings.noToursInCity : AppStrings.noToursMatch,
            icon: Icons.travel_explore,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: AppPaddings.horizontalLg,
        sliver: SliverList.list(
          children: [
            if (state.isStale) const StaleDataBanner(),
            for (final section in sections)
              RegionSectionView(
                section: section,
                onTourTap: (tour) => context.push(AppRoutes.tourDetailOf(tour.id)),
              ),
          ],
        ),
      ),
    ];
  }
}
