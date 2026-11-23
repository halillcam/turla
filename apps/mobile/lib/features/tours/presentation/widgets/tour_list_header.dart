import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// Kalkış şehri ve arama kutusu.
class TourListHeader extends StatelessWidget {
  const TourListHeader({
    required this.cityName,
    required this.onChangeCity,
    required this.onSearchChanged,
    super.key,
  });

  final String cityName;
  final VoidCallback onChangeCity;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.place_outlined, size: AppSizes.iconMd, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.departingFrom, style: textTheme.bodySmall),
                  Text(cityName, style: textTheme.titleMedium),
                ],
              ),
            ),
            TextButton(onPressed: onChangeCity, child: const Text(AppStrings.change)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: AppStrings.tourSearchHint,
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ],
    );
  }
}
