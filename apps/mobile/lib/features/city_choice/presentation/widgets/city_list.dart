import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/status_view.dart';

/// Plaka sırasıyla iller, kenarlıklı tek bir kart içinde. Seçili il vurgulanır.
class CityList extends StatelessWidget {
  const CityList({
    required this.cities,
    required this.selectedCityId,
    required this.onSelected,
    super.key,
  });

  final List<City> cities;
  final int? selectedCityId;
  final ValueChanged<City> onSelected;

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) {
      return const StatusView.message(
        message: AppStrings.cityNotFound,
        icon: Icons.location_searching,
      );
    }
    return Padding(
      padding: AppPaddings.listBody,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: ListView.separated(
            itemCount: cities.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final city = cities[index];
              return _CityTile(
                city: city,
                isSelected: city.id == selectedCityId,
                onTap: () => onSelected(city),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.city, required this.isSelected, required this.onTap});

  final City city;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: isSelected ? AppColors.primaryTint : AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppPaddings.listRow,
          child: Row(
            children: [
              Container(
                width: AppSizes.plateBoxWidth,
                height: AppSizes.plateBoxHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(
                  city.id.toString().padLeft(2, '0'),
                  style: AppTextStyles.mono.copyWith(
                    color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  city.name,
                  style: isSelected
                      ? textTheme.labelLarge?.copyWith(color: AppColors.primary)
                      : textTheme.bodyMedium,
                ),
              ),
              if (isSelected)
                const Icon(Icons.check, size: AppSizes.iconMd, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
