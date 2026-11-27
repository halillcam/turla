import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/status_view.dart';
import '../cubit/city_choice_cubit.dart';
import '../cubit/selected_city_cubit.dart';
import '../widgets/city_list.dart';
import '../widgets/city_search_field.dart';

/// İlk açılışta ve "şehri değiştir" ile açılır.
class CityChoiceScreen extends StatelessWidget {
  const CityChoiceScreen({super.key});

  Future<void> _onSelected(BuildContext context, City city) async {
    await context.read<SelectedCityCubit>().select(city);
    if (context.mounted) context.go(AppRoutes.tours);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedCityId = context.select((SelectedCityCubit cubit) => cubit.state.cityId);

    return BlocProvider(
      create: (_) => getIt<CityChoiceCubit>()..load(),
      child: Scaffold(
        // Şehir değiştirirken geri düğmesi için boş üst çubuk; ilk açılışta yok.
        appBar: selectedCityId != null ? AppBar(shape: const Border()) : null,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppPaddings.listHeader,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(AppStrings.cityChoiceTitle, style: textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.cityChoiceSubtitle,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Builder(
                      builder: (context) =>
                          CitySearchField(onChanged: context.read<CityChoiceCubit>().search),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<CityChoiceCubit, CityChoiceState>(
                  builder: (context, state) => switch (state.status) {
                    CityChoiceStatus.initial ||
                    CityChoiceStatus.loading => const StatusView.loading(),
                    CityChoiceStatus.failure => StatusView.message(
                      message: AppStrings.citiesLoadError,
                      icon: Icons.wifi_off,
                      onAction: context.read<CityChoiceCubit>().load,
                    ),
                    CityChoiceStatus.ready => CityList(
                      cities: state.visibleCities,
                      selectedCityId: selectedCityId,
                      onSelected: (city) => _onSelected(context, city),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
