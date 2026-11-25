import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';
import '../../../tickets/presentation/screens/checkout_screen.dart';
import '../../domain/entities/tour_failure.dart';
import '../cubit/tour_detail_cubit.dart';
import '../widgets/tour_detail_bottom_bar.dart';
import '../widgets/tour_detail_content.dart';

class TourDetailScreen extends StatelessWidget {
  const TourDetailScreen({required this.tourId, super.key});

  final String tourId;

  Future<void> _onBuyPressed(BuildContext context, {required bool isSignedIn}) async {
    if (!isSignedIn) {
      await context.push(AppRoutes.login);
      return;
    }
    final cubit = context.read<TourDetailCubit>();
    final tour = cubit.state.tour;
    final departure = cubit.state.selectedDeparture;
    if (tour == null || departure == null) return;

    await context.push(
      AppRoutes.checkout,
      extra: CheckoutArgs(
        tourTitle: tour.title,
        companyName: tour.companyName,
        price: tour.price,
        departureId: departure.id,
        departureAt: departure.departureAt,
      ),
    );
    // Satın alma yarıda bırakıldıysa boş koltuk sayısı değişmiş olabilir.
    if (!cubit.isClosed) await cubit.load(tourId);
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
              body: TourDetailContent(
                tour: tour!,
                selectedDepartureId: state.selectedDepartureId,
                onDepartureSelected: context.read<TourDetailCubit>().selectDeparture,
              ),
              bottomNavigationBar: TourDetailBottomBar(
                price: tour.price,
                isSignedIn: isSignedIn,
                isEnabled: state.canBuy,
                onPressed: () => _onBuyPressed(context, isSignedIn: isSignedIn),
              ),
            ),
          };
        },
      ),
    );
  }
}
