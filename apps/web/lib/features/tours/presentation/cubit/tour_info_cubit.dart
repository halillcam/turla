import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../data/services/image_resizer.dart';
import '../../domain/entities/managed_tour.dart';
import '../../domain/repositories/tour_admin_repository.dart';

/// Tur bilgileri (oluşturma / düzenleme) ve kapak görseli.
///
/// [tourId] null ise yeni tur oluşturulur; kaydedildikten sonra [TourInfoState.tour]
/// dolar ve ekran program/tarih sekmelerini açar.
class TourInfoCubit extends Cubit<TourInfoState> {
  TourInfoCubit({
    required this.companyId,
    required this.tourId,
    required this._repository,
    required CityRepository cityRepository,
    required ImageResizer imageResizer,
  }) : _cities = cityRepository,
       _resizer = imageResizer,
       super(const TourInfoState());

  final String companyId;
  final String? tourId;
  final TourAdminRepository _repository;
  final CityRepository _cities;
  final ImageResizer _resizer;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      // İller cihaz önbelleğinden gelir; sunucuya sadece ilk seferde gidilir.
      final cities = await _cities.getCities();
      final tour = tourId == null ? null : await _repository.getTour(tourId!);
      emit(TourInfoState(status: LoadStatus.ready, cities: cities, tour: tour));
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    } on CitiesUnavailableException {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: PanelFailureReason.network));
    }
  }

  Future<ActionResult<ManagedTour>> save(TourDraft draft) => _run(() async {
    final current = state.tour;
    final saved = current == null
        ? await _repository.createTour(companyId, draft)
        : await _repository.updateTour(current.id, draft);
    emit(state.copyWith(tour: saved));
    return saved;
  });

  /// Görseli ~1280 px JPEG'e küçültüp yükler. Önce tur kaydedilmiş olmalıdır.
  Future<ActionResult<ManagedTour>> uploadImage(Uint8List originalBytes) => _run(() async {
    final tour = state.tour;
    if (tour == null) throw const PanelFailure(PanelFailureReason.invalidInput);
    final jpeg = _resizer.resizeToJpeg(originalBytes);
    final updated = await _repository.uploadTourImage(tour, jpeg);
    emit(state.copyWith(tour: updated));
    return updated;
  });

  Future<ActionResult<T>> _run<T>(Future<T> Function() action) async {
    emit(state.copyWith(isBusy: true));
    final result = await runAction(action);
    emit(state.copyWith(isBusy: false));
    return result;
  }
}

final class TourInfoState extends Equatable {
  const TourInfoState({
    this.status = LoadStatus.initial,
    this.cities = const [],
    this.tour,
    this.loadFailure,
    this.isBusy = false,
  });

  final LoadStatus status;
  final List<City> cities;

  /// Kaydedilmiş tur; yeni tur henüz kaydedilmediyse null.
  final ManagedTour? tour;
  final PanelFailureReason? loadFailure;
  final bool isBusy;

  bool get isSaved => tour != null;

  TourInfoState copyWith({
    LoadStatus? status,
    List<City>? cities,
    ManagedTour? tour,
    PanelFailureReason? loadFailure,
    bool? isBusy,
  }) => TourInfoState(
    status: status ?? this.status,
    cities: cities ?? this.cities,
    tour: tour ?? this.tour,
    loadFailure: loadFailure ?? this.loadFailure,
    isBusy: isBusy ?? this.isBusy,
  );

  @override
  List<Object?> get props => [status, cities, tour, loadFailure, isBusy];
}
