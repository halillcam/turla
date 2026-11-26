import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/stale_data_banner.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../live_tour/presentation/screens/announcements_screen.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notification_center_cubit.dart';
import '../cubit/notifications_cubit.dart';
import '../utils/notification_display.dart';
import '../widgets/notification_tile.dart';

/// Bildirim kutusu. Dokununca okundu olur ve duyurunun turu açılır.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(BuildContext context, AppNotification notification) async {
    final cubit = context.read<NotificationsCubit>();
    final departureId = notification.departureId;
    await cubit.markRead(notification);
    if (departureId != null && context.mounted) {
      await context.push(
        AppRoutes.customerAnnouncementsOf(departureId),
        extra: const AnnouncementsScreenArgs(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionGranted = context.select(
      (NotificationCenterCubit cubit) => cubit.state.pushPermissionGranted,
    );
    return BlocProvider(
      create: (_) => getIt<NotificationsCubit>()..load(),
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          final cubit = context.read<NotificationsCubit>();
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.notificationsTitle),
              actions: [
                if (state.hasUnread)
                  TextButton(onPressed: cubit.markAllRead, child: const Text(AppStrings.markAllRead)),
              ],
            ),
            body: _body(context, state, cubit, permissionGranted),
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    NotificationsState state,
    NotificationsCubit cubit,
    bool permissionGranted,
  ) {
    if (state.status == NotificationsStatus.loading) return const StatusView.loading();
    if (state.status == NotificationsStatus.failure) {
      return StatusView.message(
        message: state.failure?.message ?? AppStrings.notificationsLoadError,
        icon: Icons.wifi_off,
        onAction: cubit.refresh,
      );
    }
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        padding: AppPaddings.screen,
        children: [
          if (!permissionGranted)
            const InfoBanner(
              message: AppStrings.notificationPermissionDenied,
              icon: Icons.notifications_off_outlined,
              color: AppColors.warning,
            ),
          if (state.isStale) const StaleDataBanner(message: AppStrings.showingCachedNotifications),
          if (state.notifications.isEmpty)
            const StatusView.message(
              message: AppStrings.notificationsEmpty,
              icon: Icons.notifications_none,
            )
          else
            for (final notification in state.notifications)
              NotificationTile(
                notification: notification,
                onTap: () => _open(context, notification),
              ),
        ],
      ),
    );
  }
}
