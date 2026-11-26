import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/domain/repositories/company_repository.dart';
import '../../domain/entities/company_announcement.dart';
import '../../domain/repositories/company_announcement_repository.dart';

/// Firma duyuruları. [companyId] verilirse firma alanı (okuma); verilmezse super
/// admin yönetimi (yayınla, sil; hedef firma listesi yüklenir).
class CompanyAnnouncementsCubit extends Cubit<CompanyAnnouncementsState> {
  CompanyAnnouncementsCubit({
    required this.companyId,
    required this._repository,
    required this._companyRepository,
  }) : super(const CompanyAnnouncementsState());

  final String? companyId;
  final CompanyAnnouncementRepository _repository;
  final CompanyRepository _companyRepository;

  bool get canManage => companyId == null;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final announcements = await _repository.list(companyId: companyId);
      final companies = canManage ? await _companyRepository.listCompanies() : const <Company>[];
      emit(
        CompanyAnnouncementsState(
          status: LoadStatus.ready,
          announcements: announcements,
          companies: companies,
        ),
      );
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    }
  }

  Future<ActionResult<CompanyAnnouncement>> publish({
    required String title,
    required String body,
    String? targetCompanyId,
  }) async {
    final result = await runAction(
      () => _repository.create(title: title, body: body, companyId: targetCompanyId),
    );
    final created = result.value;
    if (created != null) {
      emit(state.copyWith(announcements: [created, ...state.announcements]));
    }
    return result;
  }

  Future<ActionResult<void>> delete(CompanyAnnouncement announcement) async {
    final result = await runAction(() => _repository.delete(announcement.id));
    if (result.isSuccess) {
      emit(
        state.copyWith(
          announcements: state.announcements.where((a) => a.id != announcement.id).toList(),
        ),
      );
    }
    return result;
  }
}

final class CompanyAnnouncementsState extends Equatable {
  const CompanyAnnouncementsState({
    this.status = LoadStatus.initial,
    this.announcements = const [],
    this.companies = const [],
    this.loadFailure,
  });

  final LoadStatus status;
  final List<CompanyAnnouncement> announcements;

  /// Duyuru hedefi seçimi için (sadece super admin).
  final List<Company> companies;
  final PanelFailureReason? loadFailure;

  CompanyAnnouncementsState copyWith({
    LoadStatus? status,
    List<CompanyAnnouncement>? announcements,
    PanelFailureReason? loadFailure,
  }) => CompanyAnnouncementsState(
    status: status ?? this.status,
    announcements: announcements ?? this.announcements,
    companies: companies,
    loadFailure: loadFailure ?? this.loadFailure,
  );

  @override
  List<Object?> get props => [status, announcements, companies, loadFailure];
}
