import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_web/core/bloc/load_status.dart';
import 'package:turla_web/core/errors/panel_failure.dart';
import 'package:turla_web/features/companies/domain/repositories/company_repository.dart';
import 'package:turla_web/features/companies/presentation/cubit/company_detail_cubit.dart';
import 'package:turla_web/features/staff/domain/entities/staff_member.dart';
import 'package:turla_web/features/staff/domain/repositories/account_repository.dart';

import '../helpers/fixtures.dart';

class _MockCompanies extends Mock implements CompanyRepository {}

class _MockAccounts extends Mock implements AccountRepository {}

class _MockCities extends Mock implements CityRepository {}

void main() {
  late _MockCompanies companies;
  late _MockAccounts accounts;
  late _MockCities cities;

  const admin = StaffMember(
    id: 'a1',
    fullName: 'Fatma Yönetici',
    role: UserRole.admin,
    isActive: true,
  );

  CompanyDetailCubit build() => CompanyDetailCubit(
    companyId: companyA,
    companyRepository: companies,
    accountRepository: accounts,
    cityRepository: cities,
  );

  setUp(() {
    companies = _MockCompanies();
    accounts = _MockAccounts();
    cities = _MockCities();
    when(() => companies.getCompany(companyA)).thenAnswer((_) async => activeCompany);
    when(
      () => accounts.listMembers(companyA, roles: const [UserRole.admin]),
    ).thenAnswer((_) async => [admin]);
    when(() => cities.getCities()).thenAnswer((_) async => const []);
  });

  test('firma yöneticilerinin e-postaları yüklenir', () async {
    when(() => accounts.adminEmails(companyA)).thenAnswer((_) async => {'a1': 'fatma@maras.com'});
    final cubit = build();
    await cubit.load();

    expect(cubit.state.status, LoadStatus.ready);
    expect(cubit.state.adminEmails['a1'], 'fatma@maras.com');
    await cubit.close();
  });

  test('e-postalar okunamazsa sayfa yine açılır, sütun boş kalır', () async {
    when(
      () => accounts.adminEmails(companyA),
    ).thenThrow(const PanelFailure(PanelFailureReason.network));
    final cubit = build();
    await cubit.load();

    expect(cubit.state.status, LoadStatus.ready);
    expect(cubit.state.admins.single.id, 'a1');
    expect(cubit.state.adminEmails, isEmpty);
    await cubit.close();
  });
}
