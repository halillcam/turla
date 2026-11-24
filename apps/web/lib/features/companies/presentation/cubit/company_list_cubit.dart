import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';

/// Super admin: firma listesi, firma oluşturma ve aktif/pasif.
class CompanyListCubit extends Cubit<CompanyListState> {
  CompanyListCubit({required this._repository, required CityRepository cityRepository})
    : _cities = cityRepository,
      super(const CompanyListState());

  final CompanyRepository _repository;
  final CityRepository _cities;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final companies = await _repository.listCompanies();
      // İller cihaz önbelleğinden gelir (sunucuya sadece ilk seferde gidilir).
      final cities = await _cities.getCities();
      emit(CompanyListState(status: LoadStatus.ready, companies: companies, cities: cities));
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    } on CitiesUnavailableException {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: PanelFailureReason.network));
    }
  }

  Future<ActionResult<Company>> create(CompanyDraft draft) => _busy(() async {
    final company = await _repository.createCompany(draft);
    emit(state.copyWith(companies: _sorted([...state.companies, company])));
    return company;
  });

  Future<ActionResult<Company>> toggleActive(Company company) => _busy(() async {
    final updated = await _repository.setCompanyActive(company.id, isActive: !company.isActive);
    emit(
      state.copyWith(
        companies: [for (final c in state.companies) c.id == updated.id ? updated : c],
      ),
    );
    return updated;
  });

  Future<ActionResult<T>> _busy<T>(Future<T> Function() action) async {
    emit(state.copyWith(isBusy: true));
    final result = await runAction(action);
    emit(state.copyWith(isBusy: false));
    return result;
  }

  static List<Company> _sorted(List<Company> companies) =>
      companies..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

final class CompanyListState extends Equatable {
  const CompanyListState({
    this.status = LoadStatus.initial,
    this.companies = const [],
    this.cities = const [],
    this.loadFailure,
    this.isBusy = false,
  });

  final LoadStatus status;
  final List<Company> companies;
  final List<City> cities;
  final PanelFailureReason? loadFailure;
  final bool isBusy;

  CompanyListState copyWith({
    LoadStatus? status,
    List<Company>? companies,
    PanelFailureReason? loadFailure,
    bool? isBusy,
  }) => CompanyListState(
    status: status ?? this.status,
    companies: companies ?? this.companies,
    cities: cities,
    loadFailure: loadFailure ?? this.loadFailure,
    isBusy: isBusy ?? this.isBusy,
  );

  @override
  List<Object?> get props => [status, companies, cities, loadFailure, isBusy];
}
