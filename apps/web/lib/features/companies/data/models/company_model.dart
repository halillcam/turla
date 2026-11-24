import '../../domain/entities/company.dart';

/// `companies` satırı ↔ [Company].
abstract final class CompanyModel {
  static const String table = 'companies';
  static const String columns = 'id, name, city_id, phone, is_active';

  static Company fromRow(Map<String, dynamic> row) => Company(
    id: row['id'] as String,
    name: row['name'] as String,
    isActive: (row['is_active'] as bool?) ?? true,
    cityId: (row['city_id'] as num?)?.toInt(),
    phone: row['phone'] as String?,
  );

  static Map<String, dynamic> toRow(CompanyDraft draft) => {
    'name': draft.name.trim(),
    'city_id': draft.cityId,
    'phone': draft.phone?.trim().isEmpty ?? true ? null : draft.phone!.trim(),
  };
}
