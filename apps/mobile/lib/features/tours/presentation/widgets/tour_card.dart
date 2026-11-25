import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/tour.dart';
import '../utils/tour_display.dart';
import 'seats_badge.dart';
import 'tour_image.dart';

class TourCard extends StatelessWidget {
  const TourCard({
    required this.tour,
    required this.onTap,
    this.margin = AppMargins.cardList,
    super.key,
  });

  final Tour tour;
  final VoidCallback onTap;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final next = tour.nextDeparture;

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TourImage(imageUrl: tour.imageUrl, height: AppSizes.tourCardImageHeight),
            Padding(
              padding: AppPaddings.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    style: textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    tour.companyName,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.event,
                        size: AppSizes.iconSm,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(tour.nextDepartureLabel, style: textTheme.bodyMedium)),
                      Text(
                        Formatters.price(tour.price),
                        style: textTheme.titleMedium?.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (next != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SeatsBadge(seatsLeft: next.seatsLeft),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
