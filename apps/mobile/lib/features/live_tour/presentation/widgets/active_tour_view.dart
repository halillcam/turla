import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/phone_launcher.dart';
import '../../../../core/widgets/contact_row.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../tours/presentation/widgets/program_day_card.dart';
import '../../domain/entities/active_tour.dart';
import '../utils/live_tour_display.dart';
import 'announcement_card.dart';

/// Aktif tur içeriği: tarih, tur sorumlusu (arama), araç/şoför, son duyuru,
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
      padding: AppPaddings.screen,
      children: [
        Text(tour.tourTitle, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        InfoRow(icon: Icons.event, label: AppStrings.departureDate, value: tour.departureLabel),
        ContactRow(
          icon: Icons.support_agent,
          label: AppStrings.guideLabel,
          value: tour.guideLabel,
          callTooltip: AppStrings.callGuide,
          onCall: tour.hasGuidePhone ? () => PhoneLauncher.call(tour.guidePhone!) : null,
        ),
        ContactRow(
          icon: Icons.directions_bus,
          label: AppStrings.vehicle,
          value: tour.vehicleLabel,
          callTooltip: AppStrings.callDriver,
          onCall: tour.hasDriverPhone ? () => PhoneLauncher.call(tour.driverPhone!) : null,
        ),
        InfoRow(icon: Icons.business, label: AppStrings.organizer, value: tour.companyName),
        const SizedBox(height: AppSpacing.lg),
        if (tour.isCheckedIn) ...[
          if (lastAnnouncement != null)
            AnnouncementCard(announcement: lastAnnouncement, title: AppStrings.lastAnnouncement),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text(AppStrings.tourChat),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenAnnouncements,
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text(AppStrings.announcementsTitle),
                ),
              ),
            ],
          ),
        ] else
          const InfoBanner(
            message: AppStrings.unlocksAfterCheckIn,
            icon: Icons.lock_outline,
            color: AppColors.info,
          ),
        if (tour.program.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(AppStrings.programTitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final day in tour.program) ProgramDayCard(day: day),
        ],
      ],
    );
  }
}
