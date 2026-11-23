import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/status_view.dart';

/// Plaka sırasıyla iller. Seçili il işaretlenir.
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
      return const StatusView.message(message: AppStrings.cityNotFound, icon: Icons.search_off);
    }
    return ListView.separated(
      itemCount: cities.length,
      separatorBuilder: (_, _) => const Divider(height: AppSizes.borderWidth),
      itemBuilder: (context, index) {
        final city = cities[index];
        final isSelected = city.id == selectedCityId;
        return ListTile(
          onTap: () => onSelected(city),
          leading: CircleAvatar(
            radius: AppSizes.avatarSm / 2,
            backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceMuted,
            foregroundColor: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            child: Text(
              city.id.toString().padLeft(2, '0'),
              style: const TextStyle(fontSize: AppFontSizes.caption),
            ),
          ),
          title: Text(city.name),
          trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
        );
      },
    );
  }
}
