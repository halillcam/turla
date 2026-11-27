import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/tour.dart';
import '../utils/tour_display.dart';
import 'seats_badge.dart';
import 'tour_image.dart';

/// Tur kartı: görsel (16:10), başlık, firma, ilk kalkış, koltuk rozeti ve fiyat.
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
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: AppSizes.tourCardImageAspect,
              child: TourImage(imageUrl: tour.imageUrl),
            ),
            Padding(
              padding: AppPaddings.tourCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    style: textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    tour.companyName,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: AppSizes.iconSm,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          tour.nextDepartureLabel,
                          style: textTheme.bodySmall?.copyWith(
                            fontFeatures: AppTextStyles.tabularFigures,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: next == null ? null : SeatsBadge(seatsLeft: next.seatsLeft),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(Formatters.price(tour.price), style: AppTextStyles.price),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
