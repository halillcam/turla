import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/tour_program_day.dart';
import '../utils/tour_display.dart';

/// Tur programının bir günü: başlığa dokununca etkinlikler açılır/kapanır.
class ProgramDayCard extends StatelessWidget {
  const ProgramDayCard({required this.day, this.initiallyExpanded = true, super.key});

  final TourProgramDay day;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: AppMargins.listItem,
      child: Theme(
        // ExpansionTile'ın kendi ayırıcı çizgilerini kapat.
        data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: AppPaddings.expansionTile,
          childrenPadding: AppPaddings.expansionChildren,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(day.heading, style: textTheme.titleMedium),
          children: [
            for (final activity in day.activities)
              Padding(
                padding: AppPaddings.bulletRow,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: AppPaddings.bulletDot,
                      child: Icon(
                        Icons.circle,
                        size: AppSizes.bulletDot,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        activity,
                        style: textTheme.bodyMedium?.copyWith(
                          fontFeatures: AppTextStyles.tabularFigures,
                        ),
                      ),
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
