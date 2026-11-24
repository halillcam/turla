import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/panel_failure.dart';
import '../../features/companies/domain/entities/company.dart';
import '../../features/companies/domain/repositories/company_repository.dart';

/// Kabuğun üst çubuğunda gösterilen firma. Şirket admini için oturumdaki
/// firma kullanılır (istek atılmaz); super admin bir firmaya girince bir kez okunur.
class CompanyContextCubit extends Cubit<Company?> {
  CompanyContextCubit({required this.companyId, required this._repository, Company? known})
    : super(known?.id == companyId ? known : null);

  final String companyId;
  final CompanyRepository _repository;

  Future<void> load() async {
    if (state != null) return;
    try {
      emit(await _repository.getCompany(companyId));
    } on PanelFailure {
      // Başlık boş kalır; ekranlar kendi hatalarını gösterir.
    }
  }
}
