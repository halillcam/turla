import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/status_view.dart';
import '../../domain/entities/announcement.dart';
import '../cubit/announcements_cubit.dart';
import '../utils/live_tour_display.dart';
import '../widgets/announcement_card.dart';
import '../widgets/message_composer.dart';

/// Duyurular ekranını açan taraf gönderme iznini ve alıcı sayısını bilir.
class AnnouncementsScreenArgs {
  const AnnouncementsScreenArgs({this.canSend = false, this.recipientCount = 0});

  /// Tur sorumlusu ve tarih planlanmışsa true.
  final bool canSend;

  /// QR'ı okutulmuş yolcu sayısı (duyuru sadece onlara gider).
  final int recipientCount;
}

/// Bir tarihin duyuruları; tur sorumlusu buradan duyuru gönderir.
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({required this.departureId, this.args, super.key});

  final String departureId;
  final AnnouncementsScreenArgs? args;

  @override
  Widget build(BuildContext context) {
    final args = this.args ?? const AnnouncementsScreenArgs();
    return BlocProvider(
      create: (_) => getIt<AnnouncementsCubit>()..load(departureId),
      child: BlocConsumer<AnnouncementsCubit, AnnouncementsState>(
        listenWhen: (previous, current) =>
            previous.sentCount != current.sentCount ||
            (current.actionFailure != null && previous.actionFailure != current.actionFailure),
        listener: (context, state) {
          final message = state.actionFailure?.message ?? AppStrings.announcementSent;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) {
          final cubit = context.read<AnnouncementsCubit>();
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.announcementsTitle)),
            body: Column(
              children: [
                if (args.canSend)
                  Padding(
                    padding: AppPaddings.bannerTop,
                    child: InfoBanner(
                      message: announcementRecipientsLabel(args.recipientCount),
                      icon: Icons.groups_outlined,
                      tone: AppTone.primary,
                    ),
                  ),
                Expanded(child: _list(state, cubit)),
                if (args.canSend)
                  MessageComposer(
                    hint: AppStrings.announcementHint,
                    sendLabel: AppStrings.announcementSend,
                    maxLength: Announcement.maxLength,
                    maxLines: 6,
                    isSending: state.isSending,
                    onSend: cubit.send,
                    resetToken: state.sentCount,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _list(AnnouncementsState state, AnnouncementsCubit cubit) {
    if (state.status == AnnouncementsStatus.loading && state.announcements.isEmpty) {
      return const StatusView.loading();
    }
    if (state.status == AnnouncementsStatus.failure && state.announcements.isEmpty) {
      return StatusView.message(
        message: state.failure?.message ?? AppStrings.announcementsLoadError,
        icon: Icons.wifi_off,
        onAction: cubit.retry,
      );
    }
    if (state.announcements.isEmpty) {
      return const StatusView.message(
        message: AppStrings.announcementsEmpty,
        icon: Icons.campaign_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: cubit.retry,
      child: ListView(
        padding: AppPaddings.detailBody,
        children: [
          for (final announcement in state.announcements)
            AnnouncementCard(announcement: announcement),
        ],
      ),
    );
  }
}
