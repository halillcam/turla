import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// Kalkış şehri, bildirim zili ve arama kutusu.
class TourListHeader extends StatelessWidget {
  const TourListHeader({
    required this.cityName,
    required this.onChangeCity,
    required this.onSearchChanged,
    this.trailing,
    super.key,
  });

  final String cityName;
  final VoidCallback onChangeCity;
  final ValueChanged<String> onSearchChanged;

  /// Sağ üstte gösterilecek ek düğme (bildirim zili).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final action = trailing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.departingFrom,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      const Icon(Icons.place, size: AppSizes.iconMd, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          cityName,
                          style: textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onChangeCity,
              style: TextButton.styleFrom(textStyle: AppTextStyles.labelMedium),
              child: const Text(AppStrings.change),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: AppStrings.tourSearchHint,
            prefixIcon: Icon(Icons.search, size: AppSizes.iconMd),
          ),
        ),
      ],
    );
  }
}
