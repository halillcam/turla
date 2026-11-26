import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../cubit/notification_center_cubit.dart';

/// Üst çubuktaki bildirim zili + okunmamış rozeti. Sadece müşteri oturumunda görünür.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
      buildWhen: (previous, current) =>
          previous.isActive != current.isActive || previous.unreadCount != current.unreadCount,
      builder: (context, state) {
        if (!state.isActive) return const SizedBox.shrink();
        return IconButton(
          tooltip: AppStrings.notificationsTitle,
          onPressed: () => context.push(AppRoutes.notifications),
          icon: Badge(
            isLabelVisible: state.unreadCount > 0,
            label: Text('${state.unreadCount}'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}
