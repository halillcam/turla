import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/tour.dart';
import '../cubit/tour_list_cubit.dart';
import 'tour_card.dart';

/// Bölge başlığı ve altındaki turlar.
class RegionSectionView extends StatelessWidget {
  const RegionSectionView({required this.section, required this.onTourTap, super.key});

  final RegionSection section;
  final ValueChanged<Tour> onTourTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppMargins.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppPaddings.verticalSm,
            child: Text(
              section.region.label.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          for (final tour in section.tours) TourCard(tour: tour, onTap: () => onTourTap(tour)),
        ],
      ),
    );
  }
}
