import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';
import '../cubit/checkout_cubit.dart';
import '../widgets/checkout_form.dart';
import '../widgets/purchase_success_view.dart';

/// Tur detayından satın alma ekranına taşınan bilgiler.
class CheckoutArgs extends Equatable {
  const CheckoutArgs({
    required this.tourTitle,
    required this.companyName,
    required this.price,
    required this.departureId,
    required this.departureAt,
  });

  final String tourTitle;
  final String companyName;
  final double price;
  final String departureId;
  final DateTime departureAt;

  @override
  List<Object?> get props => [tourTitle, companyName, price, departureId, departureAt];
}

/// Yolcu bilgisi + demo ödeme. Başarılı olunca bilet ve QR gösterilir.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({required this.args, super.key});

  /// Uygulama yeniden başlatılıp sayfa adresten açılırsa null olabilir.
  final CheckoutArgs? args;

  @override
  Widget build(BuildContext context) {
    final args = this.args;
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.checkoutTitle)),
        body: const StatusView.message(
          message: AppStrings.checkoutMissing,
          icon: Icons.error_outline,
        ),
      );
    }
    final fullName = context.select((SessionBloc bloc) => bloc.state.profile?.fullName ?? '');
    final phone = context.select((SessionBloc bloc) => bloc.state.profile?.phone ?? '');

    return BlocProvider(
      create: (_) => getIt<CheckoutCubit>(),
      child: BlocConsumer<CheckoutCubit, CheckoutState>(
        // Profilde telefon yoksa sunucu satın almada yazdı: profil yenilenir ki sonraki
        // satın almada telefon dolu gelsin.
        listenWhen: (previous, current) =>
            previous.status != current.status && current.status == CheckoutStatus.success,
        listener: (context, _) {
          if (phone.trim().isEmpty) {
            context.read<SessionBloc>().add(const SessionRefreshRequested());
          }
        },
        builder: (context, state) {
          final ticket = state.ticket;
          if (state.status == CheckoutStatus.success && ticket != null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(AppStrings.purchaseSuccessTitle),
                automaticallyImplyLeading: false,
              ),
              body: PurchaseSuccessView(
                ticket: ticket,
                onMyTickets: () => context.go(AppRoutes.myTickets),
                onBackToTours: () => context.go(AppRoutes.tours),
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.checkoutTitle)),
            body: CheckoutForm(
              args: args,
              initialPassengerName: fullName,
              initialPhone: phone,
              isSubmitting: state.status == CheckoutStatus.submitting,
              failure: state.failure,
              onSubmit: (passengerName, passengerPhone) => context.read<CheckoutCubit>().purchase(
                departureId: args.departureId,
                passengerName: passengerName,
                passengerPhone: passengerPhone,
              ),
            ),
          );
        },
      ),
    );
  }
}
