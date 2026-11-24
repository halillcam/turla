import 'package:turla_core/turla_core.dart';
import 'package:turla_web/features/auth/domain/panel_session.dart';
import 'package:turla_web/features/companies/domain/entities/company.dart';
import 'package:turla_web/features/staff/domain/entities/staff_member.dart';
import 'package:turla_web/features/tours/domain/entities/departure.dart';

const String companyA = 'company-a';
const String companyB = 'company-b';

UserProfile profileWith(UserRole role, {String? companyId, bool isActive = true}) => UserProfile(
  id: 'user-${role.value}',
  email: '${role.value}@example.com',
  fullName: 'Test ${role.label}',
  role: role,
  isActive: isActive,
  companyId: companyId,
);

const Company activeCompany = Company(id: companyA, name: 'Maraş Turizm', isActive: true);
const Company passiveCompany = Company(id: companyA, name: 'Maraş Turizm', isActive: false);

PanelSession superAdminSession() => PanelSession(profile: profileWith(UserRole.superAdmin));

PanelSession adminSession() => PanelSession(
  profile: profileWith(UserRole.admin, companyId: companyA),
  company: activeCompany,
);

StaffMember guide(String id, {bool isActive = true}) =>
    StaffMember(id: id, fullName: 'Rehber $id', role: UserRole.guide, isActive: isActive);

Departure departure(String id, DateTime at, {String? guideId}) => Departure(
  id: id,
  tourId: 'tour-1',
  departureAt: at,
  capacity: 10,
  seatsLeft: 10,
  status: DepartureStatus.scheduled,
  guideId: guideId,
);
