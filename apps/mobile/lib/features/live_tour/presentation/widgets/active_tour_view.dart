import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/phone_launcher.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../tours/presentation/widgets/program_day_card.dart';
import '../../../tours/presentation/widgets/section_title.dart';
import '../../domain/entities/active_tour.dart';
import '../utils/live_tour_display.dart';
import 'announcement_card.dart';
import 'person_call_card.dart';

/// Aktif tur içeriği: tur kartı, tur sorumlusu (arama), araç/şoför, son duyuru,
/// sohbet/duyuru düğmeleri ve program.
class ActiveTourView extends StatelessWidget {
  const ActiveTourView({
    required this.tour,
    required this.onOpenChat,
    required this.onOpenAnnouncements,
    super.key,
  });

  final ActiveTour tour;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenAnnouncements;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lastAnnouncement = tour.lastAnnouncement;

    return ListView(
      padding: AppPaddings.detailBody,
      children: [
        Card(
          child: Padding(
            padding: AppPaddings.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tour.tourTitle, style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  tour.departureLabel,
                  style: textTheme.bodySmall?.copyWith(fontFeatures: AppTextStyles.tabularFigures),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(tour.companyName, style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PersonCallCard(
          label: AppStrings.guideLabel,
          name: tour.guideLabel,
          callTooltip: AppStrings.callGuide,
          onCall: tour.hasGuidePhone ? () => PhoneLauncher.call(tour.guidePhone!) : null,
        ),
        const SizedBox(height: AppSpacing.md),
        PersonCallCard(
          label: AppStrings.vehicle,
          name: tour.vehicleTitle,
          detail: tour.vehicleDriverDetail,
          isMono: tour.hasVehiclePlate,
          callTooltip: AppStrings.callDriver,
          onCall: tour.hasDriverPhone ? () => PhoneLauncher.call(tour.driverPhone!) : null,
        ),
        const SizedBox(height: AppSpacing.md),
        if (tour.isCheckedIn) ...[
          if (lastAnnouncement != null)
            AnnouncementCard(announcement: lastAnnouncement, title: AppStrings.lastAnnouncement),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: onOpenChat,
            icon: const Icon(Icons.forum_outlined, size: AppSizes.iconMd),
            label: const Text(AppStrings.tourChat),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onOpenAnnouncements,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: AppSizes.borderWidth),
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
            ),
            icon: const Icon(Icons.campaign_outlined, size: AppSizes.iconMd),
            label: const Text(AppStrings.announcementsTitle),
          ),
        ] else
          const InfoBanner(
            message: AppStrings.unlocksAfterCheckIn,
            icon: Icons.lock_outline,
            tone: AppTone.primary,
          ),
        if (tour.program.isNotEmpty) ...[
          const SectionTitle(AppStrings.programTitle),
          for (final day in tour.program) ProgramDayCard(day: day),
        ],
      ],
    );
  }
}
