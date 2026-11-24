import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/widgets/keep_tab_alive.dart';
import '../../../../core/widgets/panel_page.dart';
import '../../../../core/widgets/status_view.dart';
import '../cubit/departures_cubit.dart';
import '../cubit/tour_info_cubit.dart';
import '../cubit/tour_program_cubit.dart';
import '../widgets/departures_panel.dart';
import '../widgets/program_editor.dart';
import '../widgets/tour_info_form.dart';

/// Tur oluşturma / düzenleme. [tourId] null ise yeni tur.
/// Program ve tarih sekmeleri tur kaydedildikten sonra açılır.
class TourEditorScreen extends StatelessWidget {
  const TourEditorScreen({required this.companyId, this.tourId, super.key});

  final String companyId;
  final String? tourId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TourInfoCubit>(param1: companyId, param2: tourId)..load(),
      child: _TourEditorView(companyId: companyId, isNew: tourId == null),
    );
  }
}

class _TourEditorView extends StatelessWidget {
  const _TourEditorView({required this.companyId, required this.isNew});

  final String companyId;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TourInfoCubit>().state;
    final cubit = context.read<TourInfoCubit>();
    final tour = state.tour;

    return BlocListener<TourInfoCubit, TourInfoState>(
      // Yeni tur kaydedilince düzenleme adresine geçilir (sayfa yenilense de kalır).
      listenWhen: (previous, current) => isNew && previous.tour == null && current.tour != null,
      listener: (context, state) => context.go(AppRoutes.tour(companyId, state.tour!.id)),
      child: DefaultTabController(
        length: 3,
        child: PanelPage(
          title: tour?.title ?? (isNew ? AppStrings.newTour : ''),
          actions: [
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.tours(companyId)),
              icon: const Icon(Icons.arrow_back),
              label: const Text(AppStrings.navTours),
            ),
          ],
          child: switch (state.status) {
            LoadStatus.initial || LoadStatus.loading => const StatusView.loading(),
            LoadStatus.failure => StatusView.message(
              message: state.loadFailure!.message,
              onAction: cubit.load,
            ),
            LoadStatus.ready => Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: AppStrings.tourInfoTab),
                    Tab(text: AppStrings.tourProgramTab),
                    Tab(text: AppStrings.tourDeparturesTab),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      KeepTabAlive(
                        child: TourInfoForm(
                          key: ValueKey(tour?.id),
                          tour: tour,
                          cities: state.cities,
                          isBusy: state.isBusy,
                          onSave: cubit.save,
                          onUploadImage: cubit.uploadImage,
                        ),
                      ),
                      if (tour == null)
                        const StatusView.message(message: AppStrings.saveTourFirst)
                      else
                        KeepTabAlive(
                          child: BlocProvider(
                            create: (_) => getIt<TourProgramCubit>(param1: tour.id)..load(),
                            child: const ProgramEditor(),
                          ),
                        ),
                      if (tour == null)
                        const StatusView.message(message: AppStrings.saveTourFirst)
                      else
                        KeepTabAlive(
                          child: BlocProvider(
                            create: (_) =>
                                getIt<DeparturesCubit>(param1: companyId, param2: tour.id)..load(),
                            child: const DeparturesPanel(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}
