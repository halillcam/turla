import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';
import '../../domain/entities/tour_failure.dart';
import '../cubit/tour_detail_cubit.dart';
import '../widgets/tour_detail_bottom_bar.dart';
import '../widgets/tour_detail_content.dart';

class TourDetailScreen extends StatelessWidget {
  const TourDetailScreen({required this.tourId, super.key});

  final String tourId;

  void _onBuyPressed(BuildContext context, {required bool isSignedIn}) {
    if (!isSignedIn) {
      context.push(AppRoutes.login);
      return;
    }
    // Bilet satın alma Faz 3'te eklenecek.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.purchaseComingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.select((SessionBloc bloc) => bloc.state.isSignedIn);

    return BlocProvider(
      create: (_) => getIt<TourDetailCubit>()..load(tourId),
      child: BlocBuilder<TourDetailCubit, TourDetailState>(
        builder: (context, state) {
          final tour = state.tour;
          return switch (state.status) {
            TourDetailStatus.loading => Scaffold(
              appBar: AppBar(),
              body: const StatusView.loading(),
            ),
            TourDetailStatus.failure => Scaffold(
              appBar: AppBar(),
              body: StatusView.message(
                message: state.failure == TourFailureReason.notFound
                    ? AppStrings.tourNotFound
                    : AppStrings.tourDetailLoadError,
                icon: Icons.error_outline,
                onAction: () => context.read<TourDetailCubit>().load(tourId),
              ),
            ),
            TourDetailStatus.ready => Scaffold(
              body: TourDetailContent(tour: tour!),
              bottomNavigationBar: TourDetailBottomBar(
                price: tour.price,
                isSignedIn: isSignedIn,
                isEnabled: tour.hasAvailableSeats,
                onPressed: () => _onBuyPressed(context, isSignedIn: isSignedIn),
              ),
            ),
          };
        },
      ),
    );
  }
}
