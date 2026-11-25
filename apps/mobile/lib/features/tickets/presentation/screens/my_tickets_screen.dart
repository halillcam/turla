import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';
import '../cubit/my_tickets_cubit.dart';
import '../widgets/guest_tickets_view.dart';
import '../widgets/my_tickets_list.dart';

/// Turlarım: yaklaşan ve geçmiş biletler.
class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.select((SessionBloc bloc) => bloc.state.profile?.id);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myTicketsTitle)),
      body: SafeArea(
        child: userId == null
            ? GuestTicketsView(onLogin: () => context.push(AppRoutes.login))
            // Hesap değişirse liste baştan yüklenir.
            : BlocProvider(
                key: ValueKey(userId),
                create: (_) => getIt<MyTicketsCubit>()..load(),
                child: BlocBuilder<MyTicketsCubit, MyTicketsState>(
                  builder: (context, state) => MyTicketsList(
                    state: state,
                    onRefresh: context.read<MyTicketsCubit>().refresh,
                    onTicketTap: (ticket) => context.push(AppRoutes.ticketDetailOf(ticket.id)),
                    onBrowseTours: () => context.go(AppRoutes.tours),
                  ),
                ),
              ),
      ),
    );
  }
}
