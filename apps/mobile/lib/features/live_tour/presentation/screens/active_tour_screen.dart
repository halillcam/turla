import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/status_view.dart';
import '../cubit/active_tour_cubit.dart';
import '../utils/live_tour_display.dart';
import '../widgets/active_tour_view.dart';
import 'announcements_screen.dart';
import 'chat_screen.dart';

/// Müşterinin aktif tur ekranı (bilet detayından açılır).
class ActiveTourScreen extends StatelessWidget {
  const ActiveTourScreen({required this.departureId, super.key});

  final String departureId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ActiveTourCubit>()..load(departureId),
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.activeTourTitle)),
        body: BlocBuilder<ActiveTourCubit, ActiveTourState>(
          builder: (context, state) {
            final cubit = context.read<ActiveTourCubit>();
            final tour = state.tour;
            if (tour == null) {
              return state.status == ActiveTourStatus.failure
                  ? StatusView.message(
                      message: state.failure?.message ?? AppStrings.activeTourLoadError,
                      icon: Icons.wifi_off,
                      onAction: cubit.refresh,
                    )
                  : const StatusView.loading();
            }
            return RefreshIndicator(
              onRefresh: cubit.refresh,
              child: ActiveTourView(
                tour: tour,
                onOpenChat: () => context.push(
                  AppRoutes.customerChatOf(departureId),
                  extra: ChatScreenArgs(canWrite: tour.canWriteChat),
                ),
                onOpenAnnouncements: () => context.push(
                  AppRoutes.customerAnnouncementsOf(departureId),
                  extra: const AnnouncementsScreenArgs(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
