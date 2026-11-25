import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/tour.dart';
import 'departure_tile.dart';
import 'program_day_card.dart';
import 'section_title.dart';
import 'tour_image.dart';

/// Tur detayının kaydırılabilir içeriği.
class TourDetailContent extends StatelessWidget {
  const TourDetailContent({
    required this.tour,
    required this.selectedDepartureId,
    required this.onDepartureSelected,
    super.key,
  });

  final Tour tour;
  final String? selectedDepartureId;
  final ValueChanged<String> onDepartureSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: AppSizes.tourDetailImageHeight,
          flexibleSpace: FlexibleSpaceBar(
            background: TourImage(imageUrl: tour.imageUrl, height: AppSizes.tourDetailImageHeight),
          ),
        ),
        SliverPadding(
          padding: AppPaddings.screen,
          sliver: SliverList.list(
            children: [
              Text(
                tour.region.label,
                style: textTheme.bodySmall?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(tour.title, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('${AppStrings.organizer}: ${tour.companyName}', style: textTheme.bodyMedium),
              if (tour.description.isNotEmpty) ...[
                const SectionTitle(AppStrings.aboutTour),
                Text(tour.description, style: textTheme.bodyLarge),
              ],
              if (tour.programDays.isNotEmpty) ...[
                const SectionTitle(AppStrings.program),
                for (final day in tour.programDays) ProgramDayCard(day: day),
              ],
              if (tour.extraDetail.isNotEmpty) ...[
                const SectionTitle(AppStrings.extraDetails),
                Text(tour.extraDetail, style: textTheme.bodyMedium),
              ],
              const SectionTitle(AppStrings.departures),
              if (tour.departures.isEmpty)
                Text(AppStrings.noUpcomingDepartures, style: textTheme.bodyMedium)
              else
                for (final departure in tour.departures)
                  DepartureTile(
                    departure: departure,
                    isSelected: departure.id == selectedDepartureId,
                    onSelected: () => onDepartureSelected(departure.id),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
