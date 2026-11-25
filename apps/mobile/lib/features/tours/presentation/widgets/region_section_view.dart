import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/tour.dart';
import '../cubit/tour_list_cubit.dart';
import 'tour_card.dart';

/// Bölge başlığı (solda), "Tümünü gör" (sağda) ve yatay kayan tur kartları.
/// Kart ekrandan dar olduğu için sonraki kart sağdan görünür.
class RegionSectionView extends StatelessWidget {
  const RegionSectionView({
    required this.section,
    required this.onTourTap,
    required this.onSeeAll,
    super.key,
  });

  final RegionSection section;
  final ValueChanged<Tour> onTourTap;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppMargins.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppPaddings.horizontalLg,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.region.label.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                TextButton(onPressed: onSeeAll, child: const Text(AppStrings.seeAll)),
              ],
            ),
          ),
          // Bir bölgede birkaç tur olur; kartlar içeriğine göre aynı yükseklikte dizilir
          // (sabit yükseklik büyük yazı boyutunda taşardı).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: AppPaddings.horizontalLg,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.md,
                children: [
                  for (final tour in section.tours)
                    SizedBox(
                      width: AppSizes.tourCarouselCardWidth,
                      child: TourCard(
                        tour: tour,
                        margin: AppMargins.none,
                        onTap: () => onTourTap(tour),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
