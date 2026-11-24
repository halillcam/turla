import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../domain/entities/managed_tour.dart';
import '../../domain/repositories/tour_admin_repository.dart';

/// Firmanın tur listesi: satışa aç/kapat ve silme.
class TourListCubit extends Cubit<TourListState> {
  TourListCubit({required this.companyId, required this._repository})
    : super(const TourListState());

  final String companyId;
  final TourAdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      emit(TourListState(status: LoadStatus.ready, tours: await _repository.listTours(companyId)));
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    }
  }

  Future<ActionResult<void>> toggleActive(ManagedTour tour) => _busy(() async {
    await _repository.setTourActive(tour.id, isActive: !tour.isActive);
    emit(
      state.copyWith(
        tours: [for (final t in state.tours) t.id == tour.id ? _withActive(t, !tour.isActive) : t],
      ),
    );
  });

  Future<ActionResult<void>> delete(ManagedTour tour) => _busy(() async {
    await _repository.deleteTour(tour.id);
    emit(state.copyWith(tours: state.tours.where((t) => t.id != tour.id).toList()));
  });

  Future<ActionResult<T>> _busy<T>(Future<T> Function() action) async {
    emit(state.copyWith(isBusy: true));
    final result = await runAction(action);
    emit(state.copyWith(isBusy: false));
    return result;
  }

  static ManagedTour _withActive(ManagedTour t, bool isActive) => ManagedTour(
    id: t.id,
    companyId: t.companyId,
    title: t.title,
    description: t.description,
    extraDetail: t.extraDetail,
    price: t.price,
    cityId: t.cityId,
    region: t.region,
    isActive: isActive,
    imageUrl: t.imageUrl,
    departureCount: t.departureCount,
  );
}

final class TourListState extends Equatable {
  const TourListState({
    this.status = LoadStatus.initial,
    this.tours = const [],
    this.loadFailure,
    this.isBusy = false,
  });

  final LoadStatus status;
  final List<ManagedTour> tours;
  final PanelFailureReason? loadFailure;
  final bool isBusy;

  TourListState copyWith({
    LoadStatus? status,
    List<ManagedTour>? tours,
    PanelFailureReason? loadFailure,
    bool? isBusy,
  }) => TourListState(
    status: status ?? this.status,
    tours: tours ?? this.tours,
    loadFailure: loadFailure ?? this.loadFailure,
    isBusy: isBusy ?? this.isBusy,
  );

  @override
  List<Object?> get props => [status, tours, loadFailure, isBusy];
}
