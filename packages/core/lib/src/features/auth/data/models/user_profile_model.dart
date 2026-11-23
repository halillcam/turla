import '../../../../enums/user_role.dart';
import '../../domain/entities/user_profile.dart';

/// `profiles` satırını [UserProfile]'a çevirir.
abstract final class UserProfileModel {
  static const String columns =
      'id, role, company_id, full_name, phone, selected_city_id, is_active';

  static UserProfile fromRow(Map<String, dynamic> row, {required String email}) => UserProfile(
    id: row['id'] as String,
    email: email,
    fullName: (row['full_name'] as String?) ?? '',
    role: UserRole.fromValue(row['role'] as String),
    isActive: (row['is_active'] as bool?) ?? true,
    companyId: row['company_id'] as String?,
    phone: row['phone'] as String?,
    selectedCityId: (row['selected_city_id'] as num?)?.toInt(),
  );
}
