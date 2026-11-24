import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../../staff/domain/entities/staff_member.dart';
import '../../../staff/domain/repositories/account_repository.dart';
import '../../domain/entities/departure.dart';
import '../../domain/repositories/tour_admin_repository.dart';

/// Turun tarihleri ve tarihlere tur sorumlusu ataması.
class DeparturesCubit extends Cubit<DeparturesState> {
  DeparturesCubit({
    required this.companyId,
    required this.tourId,
    required TourAdminRepository tourRepository,
    required AccountRepository accountRepository,
  }) : _tours = tourRepository,
       _accounts = accountRepository,
       super(const DeparturesState());

  final String companyId;
  final String tourId;
  final TourAdminRepository _tours;
  final AccountRepository _accounts;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final results = await Future.wait([
        _tours.listDepartures(tourId),
        // Pasif rehberler de alınır: eski atamalarda adı görünsün.
        _accounts.listMembers(companyId, roles: const [UserRole.guide]),
      ]);
      emit(
        DeparturesState(
          status: LoadStatus.ready,
          departures: results[0] as List<Departure>,
          guides: results[1] as List<StaffMember>,
        ),
      );
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    }
  }

  Future<ActionResult<Departure>> create(DepartureDraft draft) => _busy(() async {
    final created = await _tours.createDeparture(tourId, draft);
    emit(state.copyWith(departures: _sorted([...state.departures, created])));
    return created;
  });

  Future<ActionResult<Departure>> update(String departureId, DepartureDraft draft) => _busy(
    () async {
      final updated = await _tours.updateDeparture(departureId, draft);
      emit(
        state.copyWith(
          departures: _sorted([for (final d in state.departures) d.id == updated.id ? updated : d]),
        ),
      );
      return updated;
    },
  );

  Future<ActionResult<void>> delete(String departureId) => _busy(() async {
    await _tours.deleteDeparture(departureId);
    emit(state.copyWith(departures: state.departures.where((d) => d.id != departureId).toList()));
  });

  Future<ActionResult<T>> _busy<T>(Future<T> Function() action) async {
    emit(state.copyWith(isBusy: true));
    final result = await runAction(action);
    emit(state.copyWith(isBusy: false));
    return result;
  }

  static List<Departure> _sorted(List<Departure> list) =>
      list..sort((a, b) => a.departureAt.compareTo(b.departureAt));
}

final class DeparturesState extends Equatable {
  const DeparturesState({
    this.status = LoadStatus.initial,
    this.departures = const [],
    this.guides = const [],
    this.loadFailure,
    this.isBusy = false,
  });

  final LoadStatus status;
  final List<Departure> departures;

  /// Firmanın tüm tur sorumluları (pasifler dahil).
  final List<StaffMember> guides;

  /// Yeni atamada seçilebilecekler: sadece aktifler (sunucu da denetler).
  List<StaffMember> get assignableGuides => guides.where((g) => g.isActive).toList();
  final PanelFailureReason? loadFailure;
  final bool isBusy;

  /// Listede rehber adı göstermek için.
  String? guideName(String? guideId) {
    if (guideId == null) return null;
    for (final guide in guides) {
      if (guide.id == guideId) return guide.fullName;
    }
    return null;
  }

  DeparturesState copyWith({
    LoadStatus? status,
    List<Departure>? departures,
    List<StaffMember>? guides,
    PanelFailureReason? loadFailure,
    bool? isBusy,
  }) => DeparturesState(
    status: status ?? this.status,
    departures: departures ?? this.departures,
    guides: guides ?? this.guides,
    loadFailure: loadFailure ?? this.loadFailure,
    isBusy: isBusy ?? this.isBusy,
  );

  @override
  List<Object?> get props => [status, departures, guides, loadFailure, isBusy];
}
