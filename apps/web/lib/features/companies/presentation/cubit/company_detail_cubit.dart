import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../../staff/domain/entities/new_account.dart';
import '../../../staff/domain/entities/staff_member.dart';
import '../../../staff/domain/repositories/account_repository.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';

/// Super admin: firma detayı, firma bilgisi düzenleme, firma yöneticileri.
class CompanyDetailCubit extends Cubit<CompanyDetailState> {
  CompanyDetailCubit({
    required this.companyId,
    required CompanyRepository companyRepository,
    required AccountRepository accountRepository,
    required CityRepository cityRepository,
  }) : _companies = companyRepository,
       _accounts = accountRepository,
       _cities = cityRepository,
       super(const CompanyDetailState());

  final String companyId;
  final CompanyRepository _companies;
  final AccountRepository _accounts;
  final CityRepository _cities;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final results = await Future.wait([
        _companies.getCompany(companyId),
        _accounts.listMembers(companyId, roles: const [UserRole.admin]),
      ]);
      final company = results[0] as Company?;
      if (company == null) throw const PanelFailure(PanelFailureReason.notFound);
      emit(
        CompanyDetailState(
          status: LoadStatus.ready,
          company: company,
          admins: results[1] as List<StaffMember>,
          cities: await _cities.getCities(),
        ),
      );
      await _loadAdminEmails();
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    } on CitiesUnavailableException {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: PanelFailureReason.network));
    }
  }

  /// E-postalar ayrı (Edge Function) okunur; okunamazsa sayfa yine açılır, sütun boş kalır.
  Future<void> _loadAdminEmails() async {
    try {
      final emails = await _accounts.adminEmails(companyId);
      if (!isClosed) emit(state.copyWith(adminEmails: emails));
    } on PanelFailure {
      // Sütun boş kalır.
    }
  }

  Future<ActionResult<Company>> update(CompanyDraft draft) => _busy(() async {
    final company = await _companies.updateCompany(companyId, draft);
    emit(state.copyWith(company: company));
    return company;
  });

  Future<ActionResult<Company>> toggleActive() => _busy(() async {
    final current = state.company!;
    final company = await _companies.setCompanyActive(companyId, isActive: !current.isActive);
    emit(state.copyWith(company: company));
    return company;
  });

  Future<ActionResult<CreatedAccount>> createAdmin({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) => _busy(() async {
    final created = await _accounts.createAccount(
      NewAccount(
        role: UserRole.admin,
        companyId: companyId,
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      ),
    );
    // Liste sunucudan yeniden çekilmez; açılan hesap yerelde eklenir.
    final admin = StaffMember(
      id: created.userId,
      fullName: fullName.trim(),
      role: UserRole.admin,
      isActive: true,
      phone: phone,
    );
    emit(
      state.copyWith(
        admins: [...state.admins, admin],
        adminEmails: {...state.adminEmails, created.userId: created.email},
      ),
    );
    return created;
  });

  Future<ActionResult<void>> toggleAdminActive(StaffMember admin) => _busy(() async {
    await _accounts.setActive(admin.id, isActive: !admin.isActive);
    emit(
      state.copyWith(
        admins: [
          for (final a in state.admins)
            a.id == admin.id ? a.copyWith(isActive: !admin.isActive) : a,
        ],
      ),
    );
  });

  Future<ActionResult<T>> _busy<T>(Future<T> Function() action) async {
    emit(state.copyWith(isBusy: true));
    final result = await runAction(action);
    emit(state.copyWith(isBusy: false));
    return result;
  }
}

final class CompanyDetailState extends Equatable {
  const CompanyDetailState({
    this.status = LoadStatus.initial,
    this.company,
    this.admins = const [],
    this.adminEmails = const {},
    this.cities = const [],
    this.loadFailure,
    this.isBusy = false,
  });

  final LoadStatus status;
  final Company? company;
  final List<StaffMember> admins;

  /// Yönetici e-postaları (profil kimliğine göre); super admin için Edge Function'dan.
  final Map<String, String> adminEmails;
  final List<City> cities;
  final PanelFailureReason? loadFailure;
  final bool isBusy;

  CompanyDetailState copyWith({
    LoadStatus? status,
    Company? company,
    List<StaffMember>? admins,
    Map<String, String>? adminEmails,
    PanelFailureReason? loadFailure,
    bool? isBusy,
  }) => CompanyDetailState(
    status: status ?? this.status,
    company: company ?? this.company,
    admins: admins ?? this.admins,
    adminEmails: adminEmails ?? this.adminEmails,
    cities: cities,
    loadFailure: loadFailure ?? this.loadFailure,
    isBusy: isBusy ?? this.isBusy,
  );

  @override
  List<Object?> get props => [status, company, admins, adminEmails, cities, loadFailure, isBusy];
}
