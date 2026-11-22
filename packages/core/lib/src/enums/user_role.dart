import '../constants/core_strings.dart';

/// Veritabanındaki `user_role` tipinin karşılığı.
enum UserRole {
  superAdmin('super_admin', CoreStrings.roleSuperAdmin),
  admin('admin', CoreStrings.roleAdmin),
  guide('guide', CoreStrings.roleGuide),
  customer('customer', CoreStrings.roleCustomer);

  const UserRole(this.value, this.label);

  /// Veritabanında saklanan değer.
  final String value;

  /// Arayüzde gösterilen ad.
  final String label;

  static UserRole fromValue(String value) =>
      UserRole.values.firstWhere((role) => role.value == value, orElse: () => UserRole.customer);

  /// Web paneline giriş yapabilen roller.
  bool get canUseWebPanel => this == UserRole.superAdmin || this == UserRole.admin;

  /// Mobil uygulamaya giriş yapabilen roller.
  bool get canUseMobileApp => this == UserRole.guide || this == UserRole.customer;
}
